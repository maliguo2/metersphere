<template>
  <div >
    <el-form v-loading="result.loading">
      <el-form-item v-for="(item,index) in envGroupProject" :key="index">
        <el-row type="flex" justify="space-between" :gutter="10">
          <el-col :span="6">
            <el-select v-model="item.projectId" filterable clearable style="width: 100%" @change="handleProjectChange(item)"
                        placeholder="请选择项目">
              <el-option v-for="(project, projectIndex) in projectList" :key="projectIndex" :label="project.name" :value="project.id"></el-option>
            </el-select>
          </el-col>

          <el-col :span="6">
            <el-select v-model="item.envId" filterable clearable style="width: 100%" @change="ChangeEnvId(item)"
                        placeholder="请选择环境">
              <el-option v-for="(environment, envIndex) in item.environments" :key="envIndex" :label="environment.name" :value="environment.id"></el-option>
            </el-select>
          </el-col>

          <el-col :span="6">
            <span v-if="item.domainName">{{ item.domainName }}</span>
            <el-button size="mini" icon="el-icon-s-data" @click="showInfo(item.envId)" v-else>查看域名详情</el-button>
          </el-col>

          <el-col :span="6">
            <el-input  prop="description" show-overflow-tooltip placeholder="备注" >
            </el-input>
          </el-col>
        </el-row>
      </el-form-item>
    </el-form>

    <el-dialog title="域名列表" :visible.sync="domainVisible">
      <el-table :data="conditions">
        <el-table-column prop="socket" :label="$t('load_test.domain')" show-overflow-tooltip width="180">
          <template v-slot:default="{row}">
            {{getUrl(row)}}
          </template>
        </el-table-column>
        <el-table-column prop="type" :label="$t('api_test.environment.condition_enable')" show-overflow-tooltip min-width="100px">
          <template v-slot:default="{row}">
            {{getName(row)}}
          </template>
        </el-table-column>
        <el-table-column prop="details" show-overflow-tooltip min-width="120px" :label="$t('api_test.value')">
          <template v-slot:default="{row}">
            {{getDetails(row)}}
          </template>
        </el-table-column>
        <el-table-column prop="createTime" show-overflow-tooltip min-width="120px" :label="$t('commons.create_time')">
          <template v-slot:default="{row}">
            <span>{{ row.time | timestampFormatDate }}</span>
          </template>
        </el-table-column>
      </el-table>
      <span slot="footer" class="dialog-footer">
    <el-button @click="domainVisible = false" size="mini">{{$t('commons.cancel')}}</el-button>
    <el-button type="primary" @click="domainVisible = false" size="mini">{{$t('commons.confirm')}}</el-button>
  </span>
    </el-dialog>
  </div>
</template>

<script>
  import {downloadFile, getCurrentProjectID} from "@/common/js/utils";
  import {Environment} from "@/business/components/api/test/model/EnvironmentModel";

  export default {
    name: "EditEnvironmentGroup",
    components: {},
    props: {
      envGroupId: String,
    },
    computed: {
      projectId() {
        return getCurrentProjectID();
      }
    },
    data() {
      return {
        envGroupProject: [],
        projectList: [],
        idNameMap: new Map(),
        currentProjectId: '',   //复制、创建、编辑环境时所选择项目的id
        condition: {},   //封装传递给后端的查询条件
        conditions: [],
        currentPage: 1,
        domainVisible: false,
        pageSize: 10,
        total: 0,
        projectIds: [],   //当前工作空间所拥有的所有项目id
        projectFilters: [],
        envNameList: [],
        currentEnvironment: new Environment(),
        envProjectId: '',
        environments:[],
        result: {}
      }
    },
    created() {
      this.list();
      this.getEnvironment();
    },

    activated() {
      this.list();
    },

    methods: {
      showInfo(id) {
        const index = this.environments.findIndex(e => e.id === id);
        if (index === -1) {
          return "";
        }
        let environment = this.environments[index]
        const config = JSON.parse(environment.config);
        this.conditions = config.httpConfig.conditions;
        this.domainVisible = true;
      },
      getName(row) {
        switch (row.type) {
          case "NONE":
            return this.$t("api_test.definition.document.data_set.none");
          case "MODULE":
            return this.$t("test_track.module.module");
          case "PATH":
            return this.$t("api_test.definition.api_path");
        }
      },
      getUrl(row) {
        return row.protocol + "://" + row.socket;
      },
      getDetails(row) {
        if (row && row.type === "MODULE") {
          if (row.details && row.details instanceof Array) {
            let value = "";
            row.details.forEach((item) => {
              value += item.name + ",";
            });
            if (value.endsWith(",")) {
              value = value.substr(0, value.length - 1);
            }
            return value;
          }
        } else if (row && row.type === "PATH" && row.details.length > 0 && row.details[0].name) {
          return row.details[0].value === "equals" ? this.$t("commons.adv_search.operators.equals") + row.details[0].name : this.$t("api_test.request.assertions.contains") + row.details[0].name;
        } else {
          return "";
        }
      },
      getEnvNameList(projectId) {
        this.$get("/api/environment/list/" + this.envProjectId, (response) => {
          this.environments = response.data;
          console.log(this.envNameList)
        })
      },
      list() {
        if (!this.projectList || this.projectList.length === 0) {   //没有项目数据的话请求项目数据
          this.$get("/project/listAll", (response) => {
            this.projectList = response.data;  //获取当前工作空间所拥有的项目,
            this.projectList.forEach(project => {
              this.idNameMap.set(project.id, project.name);
              this.projectIds.push(project.id);
              this.projectFilters.push({
                text: project.name,
                value: project.id,
              })
            });
            this.getEnvironments();
          })
        } else {
          this.getEnvironments()
        }
      },
      getEnvironments(projectIds){
        this.environments = [];
        if (projectIds && projectIds.length > 0) {
          this.condition.projectIds = projectIds;
        } else {
          this.condition.projectIds = this.projectIds;
        }
        let url = '/api/environment/list/' + this.currentPage + '/' + this.pageSize;
        this.result = this.$post(url, this.condition, response => {
          this.environments = response.data.listObject;
          this.total = response.data.itemCount;
        })
      },
      handleProjectChange(item) {   //项目选择下拉框选择其他项目后清空“启用条件”,因为项目变了模块也就变了。
        if (item && item.projectId) {
          this.$get('/api/environment/list/' + item.projectId, res => {
            this.$set(item, 'environments', res.data);
          });
        } else {
          this.$set(item, 'environments', []);
        }
        this.$set(item, 'envId', "");
        this.$set(item, 'domainName', "-");
      },
      ChangeEnvId(item){
        if (!item.projectId) {
          this.$warning("请先选择项目！");
          return;
        }
        let environments = item.environments;
        let index = environments.findIndex(e => e.id === item.envId);
        if (index === -1) {
          this.$set(item, "domainName", '-');
          return ;
        }
        let environment = environments[index].config;
        if (environment) {
          const config = JSON.parse(environment);
          if (config.httpConfig && !config.httpConfig.conditions) {
            if (config.httpConfig.protocol && config.httpConfig.domain) {
              let domain = config.httpConfig.protocol + "://" + config.httpConfig.domain;
              this.$set(item, "domainName", domain);
              return ;
            }
          } else {
            if (config.httpConfig.conditions.length === 1) {
              let obj = config.httpConfig.conditions[0];
              if (obj.protocol && obj.domain) {
                this.$set(item, "domainName", obj.protocol + "://" + obj.domain);
                return;
              }
            }
          }
        } else {  //旧版本没有对应的config数据,其域名保存在protocol和domain中
          this.$set(item, "domainName", environment.protocol + '://' + environment.domain);
          return ;
        }
        this.$set(item, "domainName", undefined);

      },
      // getConfig(envId){
      //   console.log(envId)
      //   this.result = this.$get("/api/environment/get/" + envId , response => {
      //     this.envGroupProject.config = response.data.config
      //     let env = this.envGroupProject.config;
      //     this.parseDomainName(env);
      //     // this.showInfo(env);
      //   })
      //
      // },
      getEnvironment(envGroupId) {
        envGroupId = this.envGroupId
        let url = '/api/environment/list/envGroupProject/' + envGroupId;
        this.result = this.$get(url, response => {
          this.envGroupProject = response.data;
          // 初始化环境数据
          this.envGroupProject.forEach(env => {
            let {projectId} = env;
            this.$get('/api/environment/list/' + projectId, res => {
              this.$set(env, 'environments', res.data);
            });
            this._parseDomainName(env);
          })
        })
      },
      // parseDomainName(item) {   //解析出环境域名用于前端展示
      //   if (!item.envId || !item.environments) {
      //     return "";
      //   }
      //   const index = item.environments.findIndex(e => e.id === item.envId);
      //   if (index === -1) {
      //     return "";
      //   }
      //   let environment = item.environments[index].config;
      //   if (environment) {
      //     const config = JSON.parse(environment);
      //     if (config.httpConfig && !config.httpConfig.conditions) {
      //       if (config.httpConfig.protocol && config.httpConfig.domain) {
      //         return config.httpConfig.protocol + "://" + config.httpConfig.domain;
      //       }
      //       return "";
      //     } else {
      //       if (config.httpConfig.conditions.length === 1) {
      //         let obj = config.httpConfig.conditions[0];
      //         if (obj.protocol && obj.domain) {
      //           return obj.protocol + "://" + obj.domain;
      //         }
      //       } else if (config.httpConfig.conditions.length > 1) {
      //         return "SHOW_INFO";
      //       } else {
      //         return "";
      //       }
      //     }
      //   } else {  //旧版本没有对应的config数据,其域名保存在protocol和domain中
      //     return environment.protocol + '://' + environment.domain;
      //   }
      // },
      _parseDomainName(item) {   //解析出环境域名用于前端展示
        if (!item) {
          this.$set(item, "domainName", "-");
          return;
        }
        let environment = item.config;
        if (environment) {
          const config = JSON.parse(environment);
          if (config.httpConfig && !config.httpConfig.conditions) {
            if (config.httpConfig.protocol && config.httpConfig.domain) {
              let domain = config.httpConfig.protocol + "://" + config.httpConfig.domain;
              this.$set(item, "domainName", domain);
            }
          } else {
            if (config.httpConfig.conditions.length === 1) {
              let obj = config.httpConfig.conditions[0];
              if (obj.protocol && obj.domain) {
                this.$set(item, "domainName", obj.protocol + "://" + obj.domain);
              }
            }
          }
        } else {  //旧版本没有对应的config数据,其域名保存在protocol和domain中
          this.$set(item, "domainName", environment.protocol + '://' + environment.domain);
        }
      },
    },

  }
</script>

<style scoped>
  .item-bar {
    width: 100%;
    background: #F9F9F9;
    padding: 5px 10px;
    box-sizing: border-box;
    border: solid 1px #e6e6e6;
  }

  .item-selected {
    background: #ECF5FF;
    border-left: solid #409EFF 5px;
  }

  .item-selected .item-right {
    visibility: visible;
  }

  .environment-edit {
    margin-left: 0;
    width: 100%;
    border: 0;
  }

  .project-item {
    padding-left: 10px;
    padding-right: 20px;
  }

  .project-item .el-select {
    margin-top: 15px;
  }
</style>

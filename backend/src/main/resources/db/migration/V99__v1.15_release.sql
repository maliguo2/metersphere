CREATE TABLE `issue_follow`
(
    `issue_id`  varchar(50) DEFAULT NULL,
    `follow_id` varchar(50) DEFAULT NULL,
    UNIQUE KEY `issue_follow_pk` (`issue_id`, `follow_id`),
    KEY `issue_follow_follow_id_index` (`follow_id`),
    KEY `issue_follow_issue_id_index` (`issue_id`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4;

-- group
INSERT INTO user_group_permission (id, group_id, permission_id, module_id)
VALUES (UUID(), 'project_group', 'PROJECT_GROUP:READ', 'PROJECT_GROUP');
INSERT INTO user_group_permission (id, group_id, permission_id, module_id)
VALUES (UUID(), 'project_group', 'PROJECT_GROUP:READ+CREATE', 'PROJECT_GROUP');
INSERT INTO user_group_permission (id, group_id, permission_id, module_id)
VALUES (UUID(), 'project_group', 'PROJECT_GROUP:READ+EDIT', 'PROJECT_GROUP');
INSERT INTO user_group_permission (id, group_id, permission_id, module_id)
VALUES (UUID(), 'project_group', 'PROJECT_GROUP:READ+DELETE', 'PROJECT_GROUP');
INSERT INTO user_group_permission (id, group_id, permission_id, module_id)
VALUES (UUID(), 'project_group', 'PROJECT_GROUP:READ+SETTING_PERMISSION', 'PROJECT_GROUP');


-- environment group
alter table api_scenario
    add environment_type varchar(20) null;

alter table api_scenario
    add environment_json longtext null;

alter table api_scenario
    add environment_group_id varchar(50) null;

update api_scenario
set environment_json = api_scenario.scenario_definition -> '$.environmentMap'
where api_scenario.environment_json is null;

update api_scenario
set environment_type = 'JSON'
where environment_type is null;

alter table test_plan_api_scenario
    add environment_type varchar(20) null comment '场景使用的环境类型';

alter table test_plan_api_scenario
    add environment_group_id varchar(50) null comment '场景使用的环境组ID';

CREATE TABLE `environment_group`
(
    `id`           varchar(50) COLLATE utf8mb4_bin NOT NULL COMMENT '环境组id',
    `name`         varchar(50) COLLATE utf8mb4_bin NOT NULL COMMENT '环境组名',
    `workspace_id` varchar(64) COLLATE utf8mb4_bin NOT NULL COMMENT '所属工作空间',
    `description`  varchar(255) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '环境组描述',
    `create_user`  varchar(50) COLLATE utf8mb4_bin  DEFAULT NULL COMMENT '创建人',
    `create_time`  bigint(13)                       DEFAULT NULL COMMENT '创建时间',
    `update_time`  bigint(13)                       DEFAULT NULL COMMENT '更新时间',
    PRIMARY KEY (`id`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_bin;


CREATE TABLE `environment_group_project`
(
    `id`                   varchar(50) COLLATE utf8mb4_bin  DEFAULT NULL,
    `environment_group_id` varchar(50) COLLATE utf8mb4_bin  DEFAULT NULL COMMENT '环境组id',
    `environment_id`       varchar(50) COLLATE utf8mb4_bin  DEFAULT NULL COMMENT 'api test environment 环境ID',
    `project_id`           varchar(50) COLLATE utf8mb4_bin  DEFAULT NULL COMMENT '项目id',
    `description`          varchar(255) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '备注'
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_bin;



return {
    up = [[
        CREATE TABLE  IF NOT EXISTS  upstream (
            upstream_id INT UNSIGNED AUTO_INCREMENT comment '主键自增',
            upstream_name VARCHAR(40) NOT NULL comment '服务名',
            connect_timeout int DEFAULT 60 comment '连接超时',
            send_timeout int DEFAULT 60 comment '发送超时',
            read_timeout int DEFAULT 60 comment '读取超时',
            create_date datetime default now() comment '建立日期',
            alive int NOT NULL DEFAULT 1 comment '是否有效',
            description VARCHAR(255) comment '描述',
            PRIMARY KEY ( upstream_id ),
            INDEX (upstream_name)
        );
        CREATE TABLE  IF NOT EXISTS  server (
    		route_id INT UNSIGNED AUTO_INCREMENT comment '主键自增',
    		upstream_id VARCHAR(40) NOT NULL comment '上游服务id',
    		route_ip VARCHAR(40) NOT NULL comment 'ip',
    		route_port int NOT NULL comment '端口',
            weight int default 1 comment '权重',
    		create_date datetime default now() comment '建立日期',
    		alive int NOT NULL DEFAULT 1 comment '是否有效',
    		description VARCHAR(255) comment '描述',
    		PRIMARY KEY ( route_id ),
            INDEX (upstream_id)
        );
        CREATE TABLE  IF NOT EXISTS  app_policy (
    		app_id INT UNSIGNED AUTO_INCREMENT comment '主键自增',
    		scope_id VARCHAR(40) NOT NULL comment '所属范围',
            app_context VARCHAR(40) NOT NULL comment '上下文',
    		policy_type VARCHAR(40) NOT NULL comment '策略类型,ip,chanel,staff',
            vi_key VARCHAR(40) NOT NULL comment '关键字',
            route_type varchar(40) no null default 'roundrobin' comment '路由算法',
    		create_date datetime default now() comment '建立日期',
    		alive int NOT NULL DEFAULT 1 comment '是否有效',
    		description VARCHAR(255) comment '描述',
    		PRIMARY KEY ( app_id ),
    		INDEX (scope_id)
        );
        CREATE TABLE  IF NOT EXISTS  sample_route_policy (
    		policy_id INT UNSIGNED AUTO_INCREMENT comment '主键自增',
            app_id INT NOT NULL comment '应用id',
            scope_id INT NOT NULL comment '所属范围',
    		type VARCHAR(40) NOT NULL comment '策略类型,ip,chanel,staff',
    		expr VARCHAR(255) NOT NULL comment '表达式',
    		target  VARCHAR(40) NOT NULL comment '策略目标',
    		create_date datetime default now() comment '建立日期',
    		alive int NOT NULL DEFAULT 1 comment '是否有效',
    		description VARCHAR(255) comment '描述',
    		PRIMARY KEY ( policy_id ),
    		INDEX (policy_type),
            INDEX (scope_id)
        );
        CREATE TABLE  IF NOT EXISTS  crm3_config (
    		id INT UNSIGNED AUTO_INCREMENT comment '主键自增',
    		type VARCHAR(40) NOT NULL comment '类型',
    		config MEDIUMTEXT NOT NULL comment '内容',
    		create_date datetime default now() comment '建立日期',
    		alive int NOT NULL DEFAULT 1 comment '是否有效',
    		description VARCHAR(255) comment '描述',
    		PRIMARY KEY ( id )
        );
    ]],
    down = [[
        DROP TABLE upstream;
        DROP TABLE route;
        DROP TABLE app_policy;
        DROP TABLE sample_route_policy;
        DROP TABLE crm3_domain;
    ]]
}

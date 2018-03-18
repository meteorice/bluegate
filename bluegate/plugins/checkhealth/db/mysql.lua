return {
    up = [[
        CREATE TABLE  IF NOT EXISTS  down_log (
            log_id INT UNSIGNED AUTO_INCREMENT comment '主键自增',
            upstream VARCHAR(40) NOT NULL comment '服务名',
            server VARCHAR(40) NOT NULL comment 'ip',
            create_date datetime default now() comment '建立日期',
            description VARCHAR(400) comment '描述',
            PRIMARY KEY ( log_id ),
            INDEX (upstream)
        );
    ]],
    down = [[
        DROP TABLE down_log;
    ]]
}

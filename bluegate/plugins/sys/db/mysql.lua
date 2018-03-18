return {
    up = [[
        CREATE TABLE  IF NOT EXISTS  nodes (
            node_id VARCHAR(40) comment '节点id',
            scope_id VARCHAR(40) comment '域',
            ip VARCHAR(40) NOT NULL comment 'ip',
            create_date datetime default now() comment '建立日期',
            alive int NOT NULL DEFAULT 1 comment '是否有效',
            description VARCHAR(255) comment '描述',
            PRIMARY KEY ( node_id )
        );

        CREATE TABLE IF NOT EXISTS cluster_events (
            id INT UNSIGNED AUTO_INCREMENT comment '主键自增',
            tag VARCHAR(40) comment '事件标签',
            node_id VARCHAR(40) comment '节点id',
            scope_id VARCHAR(40) comment '域',
            create_date datetime default now() comment '建立日期',
            data text(65535) comment '数据',
            current decimal(20) comment '时间戳',
            PRIMARY KEY ( id )
        );
    ]],
    down = [[
        DROP TABLE nodes;
        DROP TABLE cluster_events;
    ]]
}

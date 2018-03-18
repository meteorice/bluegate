return {
    up = [[
        CREATE TABLE  IF NOT EXISTS  ratelimit (
            limit_id INT UNSIGNED AUTO_INCREMENT comment '主键自增',
            limit_type VARCHAR(40) NOT NULL comment '服务名',
            limit_app VARCHAR(40) comment'根据app限制',
            rate int DEFAULT 60 comment '速率',
            burst int DEFAULT 60 comment '缓冲桶',
            create_date datetime default now() comment '建立日期',
            alive int NOT NULL DEFAULT 1 comment '是否有效',
            description VARCHAR(255) comment '描述',
            PRIMARY KEY ( limit_id )
        );
        insert into ratelimit (limit_type,rate,burst,description) values ('ALL',1000,0,'全局限速');
    ]],
    down = [[
        DROP TABLE ratelimit;
    ]]
}

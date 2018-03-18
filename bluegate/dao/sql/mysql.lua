return {
    up = [[
        CREATE TABLE  IF NOT EXISTS  b_plugins (
        		plugin_id INT UNSIGNED AUTO_INCREMENT comment '主键自增',
        		plugin_code VARCHAR(40) NOT NULL comment '名字',
        		priority int DEFAULT 900 NOT NULL comment '插件顺序',
        		create_date datetime default now() comment '建立日期',
        		alive int NOT NULL DEFAULT 1 comment '是否有效',
        		description VARCHAR(255) comment '描述',
        		PRIMARY KEY ( plugin_id ),
        		INDEX (plugin_code)
        );
    ]],
    down = [[
      DROP TABLE b_plugins;
    ]]
}

local plugin = require 'bluegate.plugins.plugin'
local util  = require 'bluegate.utils.util'
local pretty  = require 'pl.pretty'
local strx = require "pl.stringx"
local db = require "bluegate.dao.factory"
local node = require "bluegate.node"

local LogHandler = plugin.extend()
LogHandler.PRIORITY = 9000
LogHandler.VERSION = "1.0"

local client = require "resty.kafka.client"
local producer = require "resty.kafka.producer"

function LogHandler:_init()
    self.name = "logkafka"

    broker_list = {
       { host = node.conf.kafka.host, port = node.conf.kafka.port  },
    }
    ngx.log(ngx.DEBUG,"-------->logkafka")
end

function LogHandler:log()
    -- 定义json便于日志数据整理收集
    local log_json = {}
    log_json["status"] = ngx.var.status
    log_json["host"]=ngx.var.host
    log_json["server_name"]=ngx.var.server_name
    log_json["server_addr"]=ngx.var.server_addr
    log_json["server_port"]=ngx.var.server_port
    log_json["server_protocol"]=ngx.var.server_protocol
    log_json["body_bytes_sent"] = ngx.var.body_bytes_sent
    log_json["request_uri"] = ngx.var.request_uri
    log_json["upstream_response_time"] = ngx.var.upstream_response_time
    log_json["request_time"] = ngx.var.request_time
    log_json["upstream_addr"] = ngx.var.upstream_addr
    log_json["scheme"] = ngx.var.scheme
    log_json["time_local"] = ngx.var.time_local
    log_json["http_referer"] = ngx.var.http_referer
    log_json["http_user_agent"] = ngx.var.http_user_agent
    log_json["http_x_forwarded_for"] = ngx.var.http_x_forwarded_for

    log_json["remote_addr"] = ngx.var.remote_addr
    log_json["remote_user"] = ngx.var.remote_user

    log_json["mc"] = "amc"

    -- 转换json为字符串
    local message = cjson.encode(log_json);
    -- 定义kafka异步生产者
    local bp = producer:new(broker_list, { producer_type = "async" })
    local ok, err = bp:send(node.conf.kafka.topic, nil, message)
    if not ok then
        ngx.log(ngx.ERR, "kafka send err:", err)
        return
    end
    ngx.log(ngx.DEBUG,"ok=",ok)
end

return LogHandler

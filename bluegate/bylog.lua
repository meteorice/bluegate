local cjson = require "cjson"  
ngx.log(level,"status=",ngx.var.status)
ngx.log(level,"host=",ngx.var.host)
ngx.log(level,"server_name=",ngx.var.server_name)
ngx.log(level,"server_addr=",ngx.var.server_addr)
ngx.log(level,"server_port=",ngx.var.server_port)
ngx.log(level,"server_protocol=",ngx.var.server_protocol)
ngx.log(level,"body_bytes_sent=",ngx.var.body_bytes_sent)
ngx.log(level,"request_uri=",ngx.var.request_uri)
ngx.log(level,"upstream_response_time=",ngx.var.upstream_response_time)
ngx.log(level,"request_time=",ngx.var.request_time)
ngx.log(level,"upstream_addr=",ngx.var.upstream_addr)
ngx.log(level,"scheme=",ngx.var.scheme)


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
local ok, err = bp:send(cf.kafka.topic, nil, message)
if not ok then
    ngx.log(ngx.ERR, "kafka send err:", err)
    return
end
ngx.log(level,"ok=",ok)

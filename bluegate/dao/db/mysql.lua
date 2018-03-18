local mysql = require "resty.mysql"
local strx = require "pl.stringx"
local pretty = require 'pl.pretty'
local util  = require 'bluegate.utils.util'
local quote_sql_str = ngx.quote_sql_str
local mysql_pool = {}

local nlog  = ngx.log
local err = ngx.ERR
local warn  = ngx.WARN
local info  = ngx.INFO
local debug = ngx.DEBUG

ngx.log(ngx.NOTICE,strx.center("mysql start",100,"-"))

local _M = require("bluegate.dao.db.base").db("mysql")

function _M.new(conf)
    local self = _M.super.new()
    self.conf = conf
    return self
end

function _M:init()
    local conn,flag = self:getconn()
    if not flag then
        nlog(err,util.red("failed to getconn_pool mysql "))
    end
    local version, err  = conn:server_ver()
    if not version then
      return nil, err
    end

    return true
end

function _M:getconn()
    if ngx.ctx[mysql_pool] then
        return ngx.ctx[mysql_pool],true
    end
    local conf = self.conf
    local db, err = mysql:new()
    if not db then
        nlog(err,util.red("failed to instantiate mysql: " .. err))
        return nil,false
    end
    db:set_timeout(2000)
    local ok, err, errcode, sqlstate = db:connect{
        host = conf.db.host,
        port = conf.db.port,
        database = conf.db.database,
        user = conf.db.user,
        password = conf.db.password,
        charset = "utf8",
        max_packet_size = 1024 * 1024,
    }
    if not ok then
        nlog(err,util.red("failed to connect: " ..  err.. ": ".. errcode.. " ".. sqlstate))
        return nil,false
    end
    nlog(debug,util.yellow("[mysql] connected to mysql."))
    --self:keepalive(db)
    ngx.ctx[mysql_pool] = db
    return db,true
end

function _M:close()
    if ngx.ctx[mysql_pool] then
        self:keepalive(ngx.ctx[mysql_pool])
        ngx.ctx[mysql_pool] = nil
    end
end

function _M:keepalive(db)
    nlog(debug, util.yellow("[mysql] keepalive to pool, reused_times:" ..  db:get_reused_times()))
    local conf = self.conf
    local ok, err = db:set_keepalive(conf.db.max_idle_timeout, conf.db.pool_size)
    if not ok then
        ngx.say("failed to set keepalive: ", err)
        return
    end
end

local function parse_param(param)
    if not param then
        nlog(debug,util.yellow("[sql:param] nil"))
        return {}
    end
    if util.isArray(param) then
        nlog(debug,util.yellow("[sql:param] array"))
        for i, val in ipairs(param) do
            if type(val) ~= 'number' then
                param[i] = quote_sql_str(val)
            end
        end
    else
        nlog(debug,util.yellow("[sql:param]  map"))
        for key, val in pairs(param) do
            if type(val) ~= 'number' then
                param[key] = quote_sql_str(val)
            end
        end
    end
    return param
end

--todo 参数如何传
function _M:exec(sql, param)
    local p = parse_param(param)
    nlog(debug,pretty.write(p))
    local execsql = sql % p
    nlog(debug,util.yellow("[execsql] "..execsql))

    local conn = self:getconn()
    local res, error, errcode, sqlstate = conn:query(execsql)
    if not res then
        nlog(err,"[sql]\n",sql," \nbad result: ", error, ": ", errcode, ": ", sqlstate, ".")
        return
    end
    self:close()
    return res
end

function _M:insert(sql, params)
    local res, err = self:exec(sql, params)
    if not res then
        return nil, err
    end
    return true
end

function _M:update(sql, params)
    local res, err = self:exec(sql, params)
    if not res then
        return nil, err
    end
    return true
end

function _M:delete(sql, params)
    local res, err = self:exec(sql, params)
    if not res then
        return nil, err
    end
    return true
end

function _M:drop_table(table_name)
    local res, err = conn:exec("DROP TABLE IF EXISTS " .. table_name .. " ")
    if not res then
        return nil, err
    end
    return true
end

function _M:truncate_table(table_name)
    local res, err = self:exec("TRUNCATE TABLE " .. table_name .. " ")
    if not res then
        return nil, err
    end
    return true
end

return _M

local luasql = require "luasql.mysql"
local strx = require "pl.stringx"
local pretty = require 'pl.pretty'
ngx.log(ngx.NOTICE,strx.center("luasql.mysql start",100,"-"))

local _M = require("bluegate.dao.db.base").db("luasql")

function _M.new(conf)
    local self = _M.super.new()
    self.conf = conf
    return self
end

function _M:init()
    return true
end

function _M:getconn()
    local conf = self.conf
    local env = luasql.mysql()

    if not env then
        ngx.log(ngx.ERR,"failed to instantiate mysql: ", err)
        return
    end

    local conn = env:connect(conf.db.database,conf.db.user,conf.db.password,conf.db.host,conf.db.port)

    if not conn then
        ngx.log(ngx.ERR,"failed to connect: luasql")
        ngx.log(ngx.ERR,pretty.write(conf))
        return
    end
    ngx.log(ngx.NOTICE,"connected to luamysql.")
    return conn,env
end

--todo 参数如何传
function _M:query(sql, params)
    ngx.log(ngx.DEBUG, sql)
    local conn,env = self:getconn()
    local cur = conn:execute(sql)
    if not cur then
        ngx.log(ngx.ERR,"bad result: ", cur)
        return
    end
    local row = cur:fetch({},"a")
    local res = {}
    while row do
        r = {}
        for col, val in pairs(row) do
            r[col] = val
        end
        res[#res + 1] = r
        row = cur:fetch(row,"a")
    end
    conn:close()  --关闭数据库连接
    env:close()   --关闭数据库环境
    return res
end

function _M:exec(sql, params)
    local conn,env = self:getconn()
    local cur = conn:execute(sql)
    if not cur then
        ngx.log(ngx.ERR,"bad result: ", cur)
        return
    end

    conn:close()  --关闭数据库连接
    env:close()   --关闭数据库环境
    return cur
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

require 'pl.text'.format_operator()
local strx = require "pl.stringx"
local pretty = require 'pl.pretty'
local quote_sql_str = ngx.quote_sql_str
local util  = require 'bluegate.utils.util'

local nlog  = ngx.log
local err = ngx.ERR
local warn  = ngx.WARN
local info  = ngx.INFO
local debug = ngx.DEBUG
local fmt   = string.format

local _M = {}

function _M.new(conf)
    local self = {
      db_type = conf.db.type,
      daos = {},
      additional_tables = {},
      config = conf,
      plugin_names = conf.plugins or {}
    }
    nlog(debug,util.yellow("[factory] start"))
    nlog(debug,util.yellow("[factory] " .. conf.db.type))
    local db = require ("bluegate.dao.db."..self.db_type)
    self.db = db.new(conf)

    for plugin_name in pairs(self.plugin_names) do
        local ok, dao = util.load_module_if_exists("bluegate.plugins." .. plugin_name .. ".daos")
        if ok then
            self.daos[plugin_name] = dao(self)
        end
    end

    return setmetatable(self, { __index = _M })
end

--@Deprecated
function _M.sync(conf)
    local self = {}
    ngx.log(debug,util.yellow("[factory] start"))
    ngx.log(debug,"luasql")
    local db = require ("bluegate.dao.db.luasql")
    self.db = db.new(conf)
    return setmetatable(self, { __index = _M })
end

function _M:getDaos(plugin_name)
    return self.daos[plugin_name]
end

function _M:exec(sql, param)
    ngx.log(debug,util.yellow("[factory] " .. sql))
    ngx.log(debug,util.yellow("[factory] " .. tostring(param)))
    return self.db:exec(sql,param)
end

return _M

local Map = require 'pl.Map'
local config = require 'pl.config'
local pretty = require 'pl.pretty'
local tx = require 'pl.tablex'
local util = require 'bluegate.utils.util'
local DAOFactory = require "bluegate.dao.factory"

local ERR = ngx.ERR
local warn  = ngx.WARN
local info  = ngx.INFO
local debug = ngx.DEBUG
local nlog = ngx.log

local prefix = ngx.config.prefix()

local _M = {
    scope_name = 'default',
    scope_id = 'default',
    node_id = nil,
    conf = {},
    dao = {},
    worker_events = nil,
    cluster_events = nil,
    servers = {},
    route_conf = {},
    plugins_map = Map(),
    plugins = {}
}

--every worker
function _M.init()
    local sys = ngx.shared.sys
    local uuid = util.uuid()
    local ok, err =  sys:safe_add("node:id",uuid)
    if err ~= nil then
        if err == 'exists' then
            local value,flags = sys:get("node:id")
            _M.node_id = value
        end
        nlog(ERR,"create nodeid error:",err)
    else
        _M.node_id = uuid
    end
    _M.conf = config.read(prefix..'/plugins.config')
    _M.scope_id = _M.conf.comm.scope
    nlog(info,util.green(pretty.write(_M.conf)))
    _M.dao = DAOFactory.new(_M.conf)
end

return _M

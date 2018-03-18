require 'pl.text'.format_operator()
local resty_chash = require "resty.chash"
local pldir = require 'pl.dir'
local resty_roundrobin = require "resty.roundrobin"
local ck = require "resty.cookie"
local pretty  = require 'pl.pretty'
local plugin = require 'bluegate.plugins.plugin'
local util  = require 'bluegate.utils.util'
local node = require "bluegate.node"

local nlog  = ngx.log
local err   = ngx.ERR
local warn  = ngx.WARN
local info  = ngx.INFO
local debug = ngx.DEBUG
local fmt   = string.format
local timer_ev  = ngx.timer.every

local SysHandler = plugin.extend()
SysHandler.PRIORITY = 100
SysHandler.VERSION = "1.0"

function SysHandler:_init(dao)
    self.name = "sys"
    self.dao = dao
end

--
function SysHandler:init_worker()
    local self = self
    local worker_events = node.worker_events

    worker_events.register(function(data, event, source, pid)
        nlog(debug,"-------------->scope:")

        node.scope_id = tonumber(data.scope_id)
    end, "sys","scope")

    util.global_once(function()
        local res = self.dao:register(node.node_id)
    end)

    -- timer_ev(3,function(premature)
    --     nlog(err,util.red("========worker=========>"..ngx.worker.pid()))
    -- end)
end

return SysHandler

local pretty  = require 'pl.pretty'
local strx = require 'pl.stringx'
local node = require "bluegate.node"
local util  = require 'bluegate.utils.util'
local nlog  = ngx.log
local err = ngx.ERR
local warn  = ngx.WARN
local info  = ngx.INFO
local debug = ngx.DEBUG
local fmt   = string.format
local tremove = table.remove

local events = node.worker_events

return {
    ["/upstreams/policy/refresh"] = {
        put = function(req, res, next, dao)
            events.post("crm3","refresh",{})
        end
    }
}

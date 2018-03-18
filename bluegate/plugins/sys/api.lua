local pretty  = require 'pl.pretty'
local strx = require "pl.stringx"
local util  = require 'bluegate.utils.util'
local tablex = require 'pl.tablex'
local node = require "bluegate.node"
local nlog  = ngx.log
local err = ngx.ERR
local warn  = ngx.WARN
local info  = ngx.INFO
local debug = ngx.DEBUG
local fmt   = string.format

local events = node.worker_events

local prefix = ngx.config.prefix()

return {
    ["/info"] = {
        get = function(req, res, next, dao)
            res:json({
                ["node"] = node.node_id,
                ["scope_id"] = node.scope_id
            })
        end
    },
    ["/scope/:scope_id"] = {
        get = function(req, res, next, dao)
            res:send(node.scope_id)
        end,
        put = function(req, res, next, dao)
            local params = req.params
            events.post("sys","scope",{
                scope_id = params.scope_id
            })
        end
    }
}

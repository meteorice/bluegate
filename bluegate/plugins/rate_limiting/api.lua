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

return {
    ["/set_rate/:rate"] = {
        put = function(req, res, next, dao)
            local params = req.params
            if util.isNull(params.rate) then
                res:status(500):send("rate参数不能为空")
            end
            events.post("rate_limiting","set_rate",{
                rate = params.rate
            })
        end
    },
    ["/set_burst/:burst"] = {
        put = function(req, res, next, dao)
            local params = req.params
            if util.isNull(params.burst) then
                res:status(500):send("burst参数不能为空")
            end
            events.post("rate_limiting","set_burst",{
                burst = params.burst
            })
        end
    },
}

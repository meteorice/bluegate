require 'pl.text'.format_operator()
local resty_chash = require "resty.chash"
local pldir = require 'pl.dir'
local resty_roundrobin = require "resty.roundrobin"
local ck = require "resty.cookie"
local plugin = require 'bluegate.plugins.plugin'
local util  = require 'bluegate.utils.util'
local node = require "bluegate.node"
local limit_req = require "resty.limit.req"
local pretty  = require 'pl.pretty'

local nlog  = ngx.log
local err = ngx.ERR
local warn  = ngx.WARN
local info  = ngx.INFO
local debug = ngx.DEBUG
local fmt   = string.format

local RateLimitHandler = plugin.extend()
RateLimitHandler.PRIORITY = 110
RateLimitHandler.VERSION = "1.0"

local lim = nil
local error = nil
local type = 'local'

function getRateConfig(self)
    type = node.conf.ratelimit.type

    local res = self.dao:getConfig()
    nlog(debug,util.green(pretty.write(res)))
    --lim, error = limit_req.new("rate", 1000, 0)
    for _, row in ipairs(res) do
        nlog(debug,"[rate_limiting]rate:",row.rate)
        nlog(debug,"[rate_limiting]burst:",row.burst)
        lim, error = limit_req.new("rate", row.rate, row.burst)
        if not lim then
            nlog(err,"failed to instantiate a resty.limit.req object: ", error)
            return ngx.exit(500)
        end
    end
end

function RateLimitHandler:_init(dao)
    self.name = "rate_limiting"
    self.dao = dao
end

function RateLimitHandler:init_worker()
    local worker_events = node.worker_events

    local _self = self
    worker_events.register(function(data, event, source, pid)
        nlog(debug,"[rate_limiting]set_rate")
        node.plugins_map['rate_limiting']:set_rate(data)
    end, "rate_limiting","set_rate")

    worker_events.register(function(data, event, source, pid)
        nlog(debug,"[rate_limiting]set_burst")
        node.plugins_map['rate_limiting']:set_burst(data)
    end, "rate_limiting","set_burst")

    util.once_init_work(function()
        getRateConfig(_self)
    end)
end

function RateLimitHandler:set_rate(data)
    local rate = tonumber(data.rate)
    lim:set_rate(rate)
    self.dao:set_rate(rate)
end

function RateLimitHandler:set_burst(data)
    local burst = tonumber(data.burst)
    lim:set_burst(burst)
    self.dao:set_burst(burst)
end

--
function RateLimitHandler:access()
    local key = "ALL"
    --ngx.var.remote_addr
    nlog(debug,util.red("[rate_key]: "..key))
    local delay, err = lim:incoming(key, true)
    if not delay then
        if err == "rejected" then
            return ngx.exit(429)
        end
        nlog(err, "failed to limit req: ", err)
        return ngx.exit(500)
    end
    if delay >= 0.001 then
        ngx.sleep(delay)
    end
end

return RateLimitHandler

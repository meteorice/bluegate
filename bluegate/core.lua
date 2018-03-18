local pl      = require'pl.import_into'()
local resty_lock = require "resty.lock"
local pretty  = require 'pl.pretty'
local util  = require 'bluegate.utils.util'
local node = require "bluegate.node"
local ngxnow  = ngx.now
local fmt     = string.format
local ipairs = ipairs
local tostring = tostring

local version = "1.0"

local function get_now()
  return ngxnow() * 1000
end
local nlog = ngx.log
local notice=ngx.NOTICE
local warn = ngx.WARN
local err = ngx.ERR
local info = ngx.INFO

return {
    init_worker = {
        before = function()
            --once
            
            -- local worker_events = node.worker_events
            --
            -- local handler = function(data, event, source, pid)
            --     ngx.log(info,"received event; source=",source,
            --           ", event=",event,
            --           ", data=", pretty.write(data),
            --           ", from process ",pid)
            --     if event == 'change' then
            --         node.plugins_map['router']:change(data)
            --     end
            -- end
            --
            -- worker_events.register(handler, "upstream")
        end
    },
    rewrite = {
        before = function(ctx)
            ctx.BLUE_REWRITE_START = get_now()
        end,
        after = function (ctx)
            ctx.BLUE_REWRITE_TIME = get_now() - ctx.BLUE_REWRITE_START -- time spent in BLUE's rewrite_by_lua
        end
    },
    access = {
        before = function(ctx)
            local var = ngx.var
            ctx.BLUE_ACCESS_START = get_now()
            var.upstream_scheme = "http"
            ctx.context = util.get_context_path()
            ctx.app = string.sub(ctx.context,2)
        end,
        after = function (ctx)
            ctx.BLUE_ACCESS_TIME = get_now() - ctx.BLUE_ACCESS_START -- time spent in BLUE's rewrite_by_lua
            ctx.BLUE_ACCESS_ENDED_AT = get_now()
            -- time spent in BLUE before sending the reqeust to upstream
            ctx.BLUE_PROXY_LATENCY = get_now() - ngx.req.start_time() * 1000 -- ngx.req.start_time() is kept in seconds with millisecond resolution.
            ctx.BLUE_PROXIED = true
        end
    },
    balancer = {
        before = function()
            local ctx = ngx.ctx
            local addr = ctx.balancer_address
            local tries = addr.tries
            local current_try = {}
            addr.try_count = addr.try_count + 1
            tries[addr.try_count] = current_try
            current_try.balancer_start = ngx.now() * 1000
        end,
        after = function ()
            local ctx = ngx.ctx
            local addr = ctx.balancer_address
            local current_try = addr.tries[addr.try_count]
            --ngx.log(level,"try===after==",pl.pretty.write(addr))
            -- record try-latency
            local try_latency = get_now() - current_try.balancer_start
            current_try.balancer_latency = try_latency
            current_try.balancer_start = nil

            -- record overall latency
            ctx.BLUE_BALANCER_TIME = (ctx.BLUE_BALANCER_TIME or 0) + try_latency
        end
    },
    header_filter = {
        before = function(ctx)
            if ctx.BLUE_PROXIED then
                local now = get_now()
                ctx.BLUE_WAITING_TIME = now - ctx.BLUE_ACCESS_ENDED_AT -- time spent waiting for a response from upstream
                ctx.BLUE_HEADER_FILTER_STARTED_AT = now
            end
        end,
        after = function(ctx)
            local header = ngx.header
            header["bluegate"] = version
        end
    },
    body_filter = {
        after = function(ctx)
            if ngx.arg[2] and ctx.BLUE_PROXIED then
                -- time spent receiving the response (header_filter + body_filter)
                -- we could uyse $upstream_response_time but we need to distinguish the waiting time
                ctx.BLUE_RECEIVE_TIME = get_now() - ctx.BLUE_HEADER_FILTER_STARTED_AT
            end
        end
    },
    log = {
        after = function(ctx)
            --reports.log()
            --ngx.log(level,"ctx.BLUE_RECEIVE_TIME=",pretty.write(ctx))
        end
    }
}

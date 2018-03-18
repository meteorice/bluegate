require "luarocks.loader"
require "resty.core"

local Map = require 'pl.Map'

local util = require 'bluegate.utils.util'
local server = require "bluegate.utils.status"
local ngx_balancer = require "ngx.balancer"
local core = require "bluegate.core"
local node = require "bluegate.node"
local bluegate_cluster_events = require "bluegate.cluster_events"

local config = require 'pl.config'
local pretty = require 'pl.pretty'
local pl_utils = require "pl.utils"

local handler = require 'bluegate.utils.handler'

local get_last_failure = ngx_balancer.get_last_failure
local set_current_peer = ngx_balancer.set_current_peer
local set_timeouts     = ngx_balancer.set_timeouts
local set_more_tries   = ngx_balancer.set_more_tries
local ipairs = ipairs
local tostring = tostring

local err = ngx.ERR
local warn  = ngx.WARN
local info  = ngx.INFO
local debug = ngx.DEBUG
local nlog = ngx.log

cjson = require "cjson"

local cp = require "pl.comprehension"
local pl = require'pl.import_into'()

local c = cp.new()

bluegate = {}

function load_plugins(conf)
    local plugins = conf.plugins
    nlog(info,util.violet(pretty.write(plugins)))
    local sorted_plugins = {}
    for plugin, enabled in pairs(plugins) do
        if enabled == 'true' then
            local ok, handler = util.load_module_if_exists("bluegate.plugins." .. plugin .. ".handler")
            if not ok then
                return nil, plugin .. " plugin is enabled but not installed;\n" .. handler
            end

            node.plugins_map:set(plugin,handler(node.dao.daos[plugin]))
            sorted_plugins[#sorted_plugins+1] = {
              name = plugin,
              handler = node.plugins_map:get(plugin)
            }
        end
    end

    table.sort(sorted_plugins, function(a, b)
        local priority_a = a.handler.PRIORITY or 0
        local priority_b = b.handler.PRIORITY or 0
        return priority_a > priority_b
    end)

    node.plugins = sorted_plugins
end

function bluegate.init()

    nlog(info,util.red("==============blue gate=============="))
    nlog(info,util.violet(pretty.write(handler.infos())))

    node.init()
    load_plugins(node.conf)

    nlog(info,"==============load config==============")
end


function bluegate.init_worker()
    local worker_events = require "resty.worker.events"

    node.worker_events = worker_events

    local ok, error = worker_events.configure {
        shm = "worker_events", -- defined by "lua_shared_dict"
        timeout = 10,            -- life time of event data in shm
        interval = 2,           -- poll interval (seconds)

        wait_interval = 0.010,  -- wait before retry fetching event data
        wait_max = 0.5,         -- max wait time before discarding event
    }
    if not ok then
        nlog(err, util.red("failed to start event system: " .. error))
        return
    end

    node.cluster_events = bluegate_cluster_events.new {
      dao                     = node.dao,
      poll_interval           = node.conf.comm.poll_interval,
      poll_offset             = node.conf.comm.poll_offset,
    }

    core.init_worker.before()
    for _, plugin in ipairs(node.plugins) do
        plugin.handler:init_worker()
    end
end

function bluegate.balancer()
    local ctx = ngx.ctx
    core.balancer.before()

    --ngx.log(info,"before------",pl.pretty.write(node.plugins))
    for _, plugin in ipairs(node.plugins) do
        plugin.handler:balancer()
    end
    core.balancer.after()
end

function bluegate.rewrite()

    local ctx = ngx.ctx
    core.rewrite.before(ctx)
    --local cache = ngx.shared.cache
    --local plugins, flags = cache:get("plugins");
    --node.plugins = plugins
    --ngx.log(info,"rewrite------",pl.pretty.write(node))
    for _, plugin in ipairs(node.plugins) do
        plugin.handler:rewrite()
    end
    --ngx.log(info,"rewrite------")
    --ngx.log(info,pl.pretty.write(ctx))
    core.rewrite.after(ctx)
end

function bluegate.access()
    local ctx = ngx.ctx
    core.access.before(ctx)
    for _, plugin in ipairs(node.plugins) do
        plugin.handler:access()
    end
    --ngx.log(info,pl.pretty.write(ctx))
    core.access.after(ctx)
end

function bluegate.header_filter()
    local ctx = ngx.ctx
    core.header_filter.before(ctx)
    for _, plugin in ipairs(node.plugins) do
        plugin.handler:header_filter()
    end
    --ngx.log(info,"header_filter------")
    --ngx.log(info,pl.pretty.write(ctx))
    core.header_filter.after(ctx)
end

function bluegate.body_filter()
    local ctx = ngx.ctx
    if ngx.arg[2] and not ngx.is_subrequest then
        local ctx = ngx.ctx
        ngx.log(info,"body_filter------",ngx.arg[1],"=====",ngx.arg[2])
        --ngx.log(info,pl.pretty.write(ctx))
    end
    core.body_filter.after(ctx)
end

function bluegate.log()
    local ctx = ngx.ctx
    for _, plugin in ipairs(node.plugins) do
        plugin.handler:log()
    end
    --ngx.log(info,"log------")
    --ngx.log(info,pl.pretty.write(ctx))
    core.log.after(ctx)
end


function bluegate.admin_api()
    local app = require "bluegate.api.init"
    app:run()
end

return bluegate

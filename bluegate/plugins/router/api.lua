local class= require 'pl.class'
local pretty  = require 'pl.pretty'
local strx = require "pl.stringx"
local pldir = require 'pl.dir'
local util  = require 'bluegate.utils.util'
local tablex = require 'pl.tablex'
local node = require "bluegate.node"
local nlog  = ngx.log
local err = ngx.ERR
local warn  = ngx.WARN
local info  = ngx.INFO
local debug = ngx.DEBUG
local fmt   = string.format
local tremove = table.remove

local events = node.worker_events

local prefix = ngx.config.prefix()
local scripts = pldir.getfiles(prefix.."lib/bluegate/plugins/router/policy/","*_api.lua")
local policy_api = {}
for _,path in pairs(scripts) do
    local dir,delimiter,file = strx.rpartition (path,"/")
    local name,_,sufix = strx.rpartition (file,".")
    local apis = require ("bluegate.plugins.router.policy." .. name)
    policy_api = tablex.merge(apis,policy_api,true)
    nlog(debug,util.violet("[policy] loaded policy api : " .. name))
end

nlog(debug,pretty.write(policy_api))

return tablex.merge(policy_api,{
    -- all of
    ["/upstreams"] = {
        get = function(req, res, next, dao)
            res:json(node.servers)
        end
    },
    ["/upstreams/refreshall"] = {
        put = function(req, res, next, dao)
            events.post("upstream","refreshall",{})
        end
    },
    -- list server of upstream
    ["/upstreams/:upstream"] = {
        get = function(req, res, next, dao)
            local params = req.params
            if node.servers[params.upstream] then
                res:json(node.servers[params.upstream])
            else
                res:json({})
            end
        end,
        -- add server
        post = function(req, res, next, dao)
            local querystr  = req.query
            local params = req.params
            if util.isNull(querystr.server)  or util.isNull(params.upstream) then
                res:status(500):send("参数不能为空")
            end
            local weight = tonumber(querystr.weight) or 1
            local upstream = node.servers[params.upstream]
            upstream[querystr.server] = weight
            dao:addServer(params.upstream,querystr.server,weight)

            events.post("upstream","refresh",{
                upstream = params.upstream,
                server = server,
                weight = weight
            })
        end,
        -- delete server
        delete = function(req, res, next, dao)
            local querystr  = req.query
            local params = req.params
            if util.isNull(querystr.server)  or util.isNull(params.upstream) then
                res:status(500):send("参数不能为空")
            end
            local upstream = node.servers[params.upstream]
            if upstream then
                upstream[querystr.server]  = nil
                dao:delServer(params.upstream,querystr.server)
                events.post("upstream","refresh",{
                    upstream = params.upstream,
                    server = querystr.server
                })
            end
        end,
    },
    ["/upstreams/:upstream/:ip/weight"] = {
        --  weight of server
        get = function(req, res, next, dao)
            local params = req.params
            local server = node.servers
            if server[params.upstream] and server[params.upstream][params.ip] then
                res:send(server[params.upstream][params.ip])
            else
                res:send("")
            end
        end
    },
    ["/upstreams/refresh/:upstream"] = {
        put = function(req, res, next, dao)
            local params = req.params
            events.post("upstream","refresh",{
                upstream = params.upstream
            })
        end
    },
    ["/upstreams/:upstream/:ip/:weight"] = {
        -- edit weight
        put = function(req, res, next, dao)
            local params = req.params
            local server = node.servers
            if not params.weight then
                res:status(500):send("weight值不能为空")
            end
            if server[params.upstream] and server[params.upstream][params.ip] then
                dao:editWeight(params.upstream,params.ip,params.weight)
                events.post("upstream","weight",{
                    upstream = params.upstream,
                    server = params.ip,
                    weight = tonumber(params.weight)
                })
            end
        end
    }
},true)

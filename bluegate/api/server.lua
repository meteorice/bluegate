local util = require 'bluegate.utils.util'
local strx = require "pl.stringx"
local pretty  = require 'pl.pretty'
local tablex = require "pl.tablex"
local sip = require 'pl.sip'
local lor = require "lor.index"
local node = require "bluegate.node"

local nlog  = ngx.log
local err = ngx.ERR
local warn  = ngx.WARN
local info  = ngx.INFO
local debug = ngx.DEBUG
local fmt   = string.format
local ipairs = ipairs
local string_lower = string.lower

local support_methos = tablex.readonly({ get = true,post = true,head = true,options = true,put = true,patch = true,delete = true,trace = true})


local app = lor()

app:get("/", function(req, res, next)
    nlog(debug,"pid=",ngx.worker.pid())
    res:send(pretty.write(node))
end)

function auth(req, res, next)
    nlog(debug,"check auth")
    next()
end

function add_apis(routes, router, plugin)
    for route_path, methods in pairs(routes) do
        nlog(debug,"route_path=",route_path," methods=",pretty.write(methods))
        for method, func in pairs(methods) do
            local m = string_lower(method)
            if support_methos[m] then
                router[m](router, route_path,{auth},
                function (req, res, next)
                    local status, msg = pcall(func,req, res, next, node.dao.daos[plugin])
                    if not status then
                        error(msg)
                    end
                end)
                nlog(debug,"sub=",route_path)
            end
        end
    end
end

--loading plugins apis
if node.conf and node.conf.plugins then
    for plugin, enabled in pairs(node.conf.plugins) do
        if enabled == 'true' then
            local ok,mod = util.load_module_if_exists("bluegate.plugins." .. plugin .. ".api")
            if ok then
                nlog(debug,pretty.write(mod))
                local router = lor:Router()
                add_apis(mod, router, plugin)
                app:use(plugin, router())
                nlog(debug,"path=",plugin)
            end
        else
            nlog(debug, "No API endpoints loaded for plugin: ", plugin)
        end
    end
end

app:erroruse(function(err, req, res, next)
    if req:is_found() ~= true then
        res:status(404):send("404! page not found!")
    else
        ngx.log(ngx.ERR, err)
        res:status(500):send("unknown error")
    end
end)



return app

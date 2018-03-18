local util  = require 'bluegate.utils.util'
local node = require "bluegate.node"
local plugin = require 'bluegate.plugins.plugin'
local pretty  = require 'pl.pretty'
local strx = require "pl.stringx"
local shared = ngx.shared
local re_find = ngx.re.find
local sub = string.sub
local stream_sock = ngx.socket.tcp

local nlog  = ngx.log
local err = ngx.ERR
local warn  = ngx.WARN
local info  = ngx.INFO
local debug = ngx.DEBUG
local fmt   = string.format


local HealthHandler = plugin.extend()
HealthHandler.PRIORITY = 200
HealthHandler.VERSION = "1.0"

function HealthHandler:_init(dao)
    self.name = "checkhealth"
    self.dao = dao.checkhealth
end

local function peer_error(dao,ctx,upstream_name,server, ...)
    nlog(err,...)
    local upstream = node.servers[upstream_name]
    if upstream then
        upstream[server]  = nil
    end
    dao:logs(upstream_name,server,strx.join('', {...}))
    local worker_events = node.worker_events
    worker_events.post("upstream","unalive",{
        upstream = upstream_name,
        server = server
    })
end

function HealthHandler:init_worker()
    local dao = self.dao
    local handler = function (premature)
        if premature then
            return
        end
        local dict = shared["cache"]
        local statuses =  { [200] = true , [302] = true}
        local concur = 1
        if not concur then
            concur = 1
        end
        local ctx = {
            timeout = 2000,
            interval = 10 / 1000,
            dict = dict,
            http_req = "GET /status HTTP/1.0\r\nHost: bluegate.com\r\n\r\n",
            statuses = statuses,
            version = 0,
            concurrency = concur,
        }
        ctx.timeout = 1000
        local sock, error = stream_sock()
        if not sock then
            nlog(err,"failed to create stream socket: ", error)
            return
        end
        sock:settimeout(ctx.timeout)
        if node.servers then
            local req = ctx.http_req
            local statuses = ctx.statuses
            --nlog(debug,pretty.write(node.servers))
            for upstream,servers in pairs(node.servers) do
                nlog(debug,'check upstream -> ',upstream)
                for server,weight in pairs(servers) do
                    nlog(debug,'check server -> ',server)
                    local map = strx.split(server,':')
                    local ok, error = sock:connect(map[1], map[2])
                    if not ok then
                        --todo:the server unreachable , delete server
                        nlog(debug,"the server : ",server," unreachable, error : ",error)
                    end
                    local bytes, error = sock:send(req)
                    if not bytes then
                        peer_error(dao,ctx,upstream,server,"failed to send request to ", server, " error: ", error)
                    end

                    local status_line, error = sock:receive()
                    nlog(debug,status_line)
                    if not status_line then
                        peer_error(dao,ctx,upstream,server,"failed to receive status line from ", server, " error : ", error)
                        if error == "timeout" then
                            sock:close()  -- timeout errors do not close the socket.
                        end
                        return
                    end

                    if statuses then
                        local from, to, error = re_find(status_line, [[^HTTP/\d+\.\d+\s+(\d+)]], "joi", nil, 1)
                        if not from then
                            peer_error(dao,ctx,upstream,server,"bad status line from ", server, " status_line: ",status_line)
                            sock:close()
                            return
                        end
                        local status = tonumber(sub(status_line, from, to))
                        if not statuses[status] then
                            peer_error(dao,ctx,upstream,server, "bad status code from ",server, " status: ", status)
                            sock:close()
                            return
                        end
                    end
                    sock:close()
                end
            end
        end
    end
    local ok, error = ngx.timer.every(5,handler)
end




return HealthHandler

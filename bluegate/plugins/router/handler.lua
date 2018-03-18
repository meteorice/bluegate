require 'pl.text'.format_operator()
local resty_chash = require "resty.chash"
local pldir = require 'pl.dir'
local resty_roundrobin = require "resty.roundrobin"
local ck = require "resty.cookie"
local plugin = require 'bluegate.plugins.plugin'
local util  = require 'bluegate.utils.util'
local node = require "bluegate.node"
local pretty  = require 'pl.pretty'
local strx = require "pl.stringx"
local ngx_balancer = require "ngx.balancer"
local get_last_failure = ngx_balancer.get_last_failure
local set_current_peer = ngx_balancer.set_current_peer
local set_timeouts     = ngx_balancer.set_timeouts
local set_more_tries   = ngx_balancer.set_more_tries

local nlog  = ngx.log
local err = ngx.ERR
local warn  = ngx.WARN
local info  = ngx.INFO
local debug = ngx.DEBUG
local fmt   = string.format


local RouterHandler = plugin.extend()
RouterHandler.PRIORITY = 120
RouterHandler.VERSION = "1.0"

function RouterHandler:_init(dao)
    self.name = "router"
    self.dao = dao
end

function RouterHandler:init_worker()
    local worker_events = node.worker_events
    local cluster_events = node.cluster_events
    -- worker_events.register(function(data, event, source, pid)
    --     ngx.log(info,"received event; source=",source,
    --           ", event=",event,
    --           ", data=", pretty.write(data),
    --           ", from process ",pid)
    -- end,"upstream")
    local self = self
    worker_events.register(function(data, event, source, pid)
        nlog(debug,"-------------->unalive")
        self:unalive(data)
        cluster_events:broadcast("upstream:refresh", cjson.encode(data))
    end, "upstream","unalive")

    -- for api
    worker_events.register(function(data, event, source, pid)
        nlog(debug,"-------------->refresh")
        --node.plugins_map['router']:refresh(data)
        worker_events.post("balancer", "refresh",data)
        cluster_events:broadcast("upstream:refresh", cjson.encode(data))
    end, "upstream","refresh")

    worker_events.register(function(data, event, source, pid)
        self:refresh(data)
    end,"balancer","refresh")

    -- for api
    worker_events.register(function(data, event, source, pid)
        nlog(debug,"-------------->refreshall")
        worker_events.post("balancer", "refreshall",data)
        cluster_events:broadcast("upstream:refreshall", "{}")
    end, "upstream","refreshall")

    worker_events.register(function(data, event, source, pid)
        loadconfig(self)
    end,"balancer","refreshall")


    worker_events.register(function(data, event, source, pid)
        nlog(debug,"-------------->change_weight")
        self:change_weight(data)
        cluster_events:broadcast("upstream:refresh", cjson.encode(data))
    end,"upstream","weight")

    local prefix = ngx.config.prefix()
    local scripts = pldir.getfiles(prefix.."lib/bluegate/plugins/router/policy/","*_init_work.lua")
    for _,path in pairs(scripts) do
        local dir,delimiter,file = strx.rpartition (path,"/")
        local name,_,sufix = strx.rpartition (file,".")
        local policy = require ("bluegate.plugins.router.policy." .. name)
        policy.init_worker(self,worker_events)
        nlog(debug,util.blue("[policy] loaded policy script " .. name))
    end

    cluster_events:subscribe("upstream:refreshall",function(data)
        local ok, error = worker_events.post("balancer", "refreshall",data)
        if not ok then
            nlog(err, "failed broadcasting upstream:refreshall to workers: ", error)
        end
    end)

    cluster_events:subscribe("upstream:refresh",function(data)
        local ok, error = worker_events.post("balancer", "refresh",data)
        if not ok then
            nlog(err, "failed broadcasting upstream:refresh to workers: ", error)
        end
    end)

    --
    util.once_init_work(function()
        loadconfig(self)
    end)
end

local function loadupstream(upstream, servers)
    local chash_up = resty_chash:new(servers)
    package.loaded[fmt("%s_chash",upstream)] = chash_up
    local rr_up = resty_roundrobin:new(servers)
    package.loaded[fmt("%s_rr",upstream)] = rr_up
    nlog(debug,"loadupstream = > ",fmt("%s_rr",upstream))
end

-- refresh weight
function RouterHandler:change_weight(data)
    if not data or not data.upstream then
        if data then
            nlog(info,pretty.write(data))
        end
        error("参数不能为空")
    end
    local upstream = data.upstream
    local server = data.server
    local servers = node.servers
    servers[upstream][server] = data.weight
    loadupstream(upstream,servers[upstream])
end

-- delete unalive server
function RouterHandler:unalive(data)
    if not data or not data.upstream  or not data.server then
        if data then
            nlog(info,pretty.write(data))
        end
        error("参数不能为空")
    end
    self.dao:delServer(data.upstream,data.server)
    self:refresh(data)
end

-- for event : edit server
function RouterHandler:refresh(data)
    if not data or not data.upstream then
        if data then
            nlog(info,pretty.write(data))
        end
        error("参数不能为空")
    end
    local upstream = data.upstream
    --local sql = [[select * from server where alive = 1 and upstream_id=(select upstream_id from upstream where upstream_name=%s)]]
    --local res = dao:exec(sql, {upstream})
    local res = self.dao:findServerByName(upstream)
    local map = {}
    for _, row in ipairs(res) do
        nlog(debug,util.green(fmt("upstream=%s ip=%s port=%s",upstream,row.route_ip,row.route_port)))
        local server = fmt("%s:%s", row.route_ip, row.route_port)
        map[server] = tonumber(row.weight)
    end

    nlog(info,pretty.write(map))

    loadupstream(upstream,map)
end

function loadconfig(self)
    --1.route info
    local dao = node.dao
    local res = self.dao:upstream()
    for _, r in ipairs(res) do
        local upstream_id = r.upstream_id
        local upstream = r.upstream_name
        local map = {}
        --local res = dao:exec("select * from server where alive = 1 and upstream_id = %s",{upstream_id})
        local res = self.dao:findServerById(upstream_id)
        local nodes  =  {}
        --local str_null = string.char(0)
        for _, row in ipairs(res) do
            nlog(debug,util.green(fmt("upstream=%s ip=%s port=%s",upstream,row.route_ip,row.route_port)))
            local server = fmt("%s:%s", row.route_ip, row.route_port)
            map[server] = tonumber(row.weight)
        end
        node.servers[upstream] = map
        nlog(info,util.green(pretty.write(map)))

        loadupstream(upstream,map)
    end
    nlog(debug,util.green(pretty.write(node.servers)))
    --2.policy info
    local config = {}
    --res = dao:exec("select * from app_policy where alive = 1 and scope_id = %d" ,{node.scope_id})
    res = self.dao:findPolicyByscope(node.scope_id)
    for _, r in ipairs(res) do
        local current_app = {}
        config[r.app_context] = current_app
        current_app.type = r.policy_type
        current_app.inkey = r.vi_key
        current_app.route_type = r.route_type
        --row = dao:exec("select * from sample_route_policy where alive = 1 and app_id = %d and scope_id = %d ", {r.app_id ,node.scope_id})
        row = self.dao:findSampleRoutePolicy(r.app_id ,node.scope_id)
        local map = {}
        current_app.policy = map
        for _, rr in ipairs(row) do
            local policy_type = rr.type
            if not map[policy_type] then
                map[policy_type] = {}
            end
            map[policy_type][rr.expr] = rr.target
        end
    end

    node.route_conf = config
    nlog(debug,util.green(pretty.write(config)))
end


function get_ip(self,ctx)
    local config = node.route_conf
    local route = ngx.shared.route
    --local cache = ngx.shared.cache
    local upstream = ctx.app

    local map = ""
    --todo:插件配置
    nlog(debug,pretty.write(config))
    local route_type = config[upstream].route_type
    --local route_type,flags = cache:get("route:type")
    nlog(debug,"[route] route_type=" , route_type)
    if route_type == 'chash' then
        --policy
        local policy_type = config[upstream].type
        local inkey = config[upstream].inkey
        local policyconfig = config[upstream].policy[policy_type]
        local policyaction = require ("bluegate.plugins.router.policy."..policy_type)
        upstream = policyaction.router(self,policyconfig,inkey)
        nlog(debug,"[route] upstream=" , upstream)
        -- session hold by cookies
        -- consistent hashing
        local cookie, error = ck:new()
        if not cookie then
            nlog(err, error)
            return
        end
        local stickyid, error = cookie:get("stickyid")
        if not stickyid then
            local stickyid = util.uuid()
            local ok, error = cookie:set({key="stickyid",value=stickyid,path=ctx.context})
        end

        local router_inst = fmt("%s_chash",upstream)
        nlog(debug,"get resty_chash router ",router_inst)
        local chash_up = package.loaded[router_inst]
        nlog(debug,"[route] stickyid=" , stickyid)
        map = chash_up:find(stickyid)
        nlog(debug,"[route] chash=",map)
    else
        nlog(debug,"[route] upstream=" , upstream)
        --policy
        local policy_type = config[upstream].type
        local inkey = config[upstream].inkey
        local policyconfig = config[upstream].policy[policy_type]
        local policyaction = require ("bluegate.plugins.router.policy."..policy_type)
        upstream = policyaction.router(self,policyconfig,inkey)
        --todo: ab router
        local router_inst = fmt("%s_rr",upstream)
        nlog(debug,"get resty_roundrobin router ",router_inst)
        local rr_up = package.loaded[router_inst]
        if not rr_up then
            ngx.status = ngx.HTTP_NOT_FOUND
            ngx.say(fmt("找不到注册服务[%s]",upstream))
            ngx.exit(ngx.OK)
        end
        map = rr_up:find()
        nlog(debug,"[route] roundrobin=",map)
    end
    --todo:check style
    local map = strx.split(map,':')
    return map[1],tonumber(map[2])
end

function RouterHandler:access()
    local ctx = ngx.ctx

    local host,port = get_ip(self,ctx)
    local balancer_address = {
        type                 = "utils.hostname_type(upstream_url_t.host)",  -- the type of `host`; ipv4, ipv6 or name
        host                 = host,  -- target host per `upstream_url`
        port                 = port,  -- final target port
        try_count            = 0,              -- retry counter
        tries                = {},             -- stores info per try
        retries              = 2,    -- number of retries for the balancer
        connect_timeout      = node.conf.upstream_connect_timeout or 60,
        send_timeout         = node.conf.upstream_send_timeout or 60,
        read_timeout         = node.conf.upstream_read_timeout or 60,
        -- ip                = nil,            -- final target IP address
        -- balancer          = nil,            -- the balancer object, in case of a balancer
        -- hostname          = nil,            -- the hostname belonging to the final target IP
    }
    ctx.balancer_address = balancer_address
    --nlog(debug,pretty.write(balancer_address))
end

function RouterHandler:balancer()
    local ctx = ngx.ctx
    local addr = ctx.balancer_address
    local tries = addr.tries
    local current_try = tries[addr.try_count]

    --nlog(debug,"try===1==",pretty.write(addr))
    if addr.try_count > 1 then
        local previous_try = tries[addr.try_count - 1]
        previous_try.state, previous_try.code = get_last_failure()
        addr.host, addr.port = get_ip(self,ctx)
    else
        -- first try, so set the max number of retries
        local retries = addr.retries
        if retries > 0 then
            set_more_tries(retries)
        end
    end

    current_try.ip   = addr.host
    current_try.port = addr.port
    local ok, err = set_current_peer(addr.host,addr.port)
    if not ok then
      nlog(ngx.ERR, "failed to set the current peer (address: ",
              tostring(addr.host), " port: ", tostring(addr.port),"): ",
              tostring(err))

      return responses.send(500)
    end

    ok, err = set_timeouts(addr.connect_timeout, addr.send_timeout, addr.read_timeout )
    if not ok then
      nlog(ngx.ERR, "could not set upstream timeouts: ", err)
    end

end
return RouterHandler

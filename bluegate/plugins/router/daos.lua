require 'pl.text'.format_operator()
local util  = require 'bluegate.utils.util'
local node = require "bluegate.node"
local strx = require "pl.stringx"
local pretty  = require 'pl.pretty'
local class= require 'pl.class'
local pldir = require 'pl.dir'

local nlog  = ngx.log
local err = ngx.ERR
local warn  = ngx.WARN
local info  = ngx.INFO
local debug = ngx.DEBUG
local fmt   = string.format
local prefix = ngx.config.prefix()

local DAO = class()

function DAO:_init(db)
    self.db = db
end

-- add server
function DAO:addServer(upstream,server,weight)
    local weight = weight or 1
    local sql = [[insert into server (upstream_id,route_ip,route_port,weight)
    select (select upstream_id from upstream where upstream_name = %s),%s,%d,%d from dual]]
    local map = strx.split(server,":")
    self.db:exec(sql,{ upstream , map[1] , tonumber(map[2]) ,weight })
end

-- edit weight
function DAO:editWeight(upstream,server,weight)
    local weight = weight or 1
    local sql = [[update server set weight = %d where
    upstream_id=(select upstream_id from upstream where upstream_name = %s)
    and route_ip = %s and route_port = %d]]
    local map = strx.split(server,":")
    self.db:exec(sql,{ tonumber(weight), upstream , map[1] , tonumber(map[2]) })
end

-- delete server
function DAO:delServer(upstream,server)
    local map = strx.split(server,':')
    local sql = [[delete from server where upstream_id=
    (select upstream_id from upstream where upstream_name = %s)
    and route_ip=%s  and route_port = %d]]
    self.db:exec(sql , {upstream,map[1],tonumber(map[2])})
end

-- query all upstream
function DAO:upstream()
    local sql = 'select * from upstream'
    return self.db:exec(sql)
end
-- query server by upstream_id
function DAO:findServerById(upstream_id)
    return self.db:exec("select * from server where alive = 1 and upstream_id = %s",{upstream_id})
end
-- query server by upstream_name
function DAO:findServerByName(upstream)
    return self.db:exec("select * from server where alive = 1 and upstream_id=(select upstream_id from upstream where upstream_name=%s)",{upstream})
end

function DAO:findPolicyByscope(scope_id)
    return self.db:exec("select * from app_policy where alive = 1 and scope_id = %s" ,{scope_id})
end

function DAO:findSampleRoutePolicy(app_id,scope_id)
    return self.db:exec("select * from sample_route_policy where alive = 1 and app_id = %d and scope_id = %s " ,{app_id ,scope_id})
end

--inherit policy's dao
--local scripts = pldir.getfiles(prefix.."lib/bluegate/plugins/router/policy/","*_daos.lua")
local ALLDAO = class(DAO)
nlog(debug,util.green(pretty.write(node)))
local routePolicy = node.conf.route
if not routePolicy then
    routePolicy.policy= 'default'
    nlog(err,util.red("plugins.config miss route info"))
end


local daos = require ("bluegate.plugins.router.policy." .. routePolicy.policy .. "_daos")
ALLDAO = daos(ALLDAO)
-- supplement init
function ALLDAO:_init(db)
    self.db = db
end
nlog(debug,util.violet("[daos] loaded policy daos ", routePolicy.policy))
-- for _,path in pairs(scripts) do
--     local dir,delimiter,file = strx.rpartition (path,"/")
--     local name,_,sufix = strx.rpartition (file,".")
--     local daos = require ("bluegate.plugins.router.policy." .. name)
--     ALLDAO = daos(ALLDAO)
--     -- supplement init
--     function ALLDAO:_init(db)
--         self.db = db
--     end
--     nlog(debug,util.violet("[daos] loaded policy daos ", name))
-- end
return ALLDAO

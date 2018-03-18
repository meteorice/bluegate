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

function DAO:register(nodeid)
    local sql = [[replace into nodes (node_id,scope_id,ip,description) values (%s,%s,%s,%s)]]
    self.db:exec(sql,{ node.node_id, node.scope_id, '', '启动'})
    --nlog(err,"node_id:"..node.node_id.." scope_id:"..node.scope_id)
end

function DAO:findNodes()
    local sql = [[select ip from nodes where alive = %d ]]
    return self.db:exec(sql, 1)
end



return DAO

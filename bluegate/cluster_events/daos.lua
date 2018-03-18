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

function DAO:getEventsByTag(tags, min_at, max_at)
    local param_tag = ""
    if util.isArray(tags) then
        for i, val in ipairs(tags) do
            if i == 1 then
                param_tag = fmt("'%s'", val)
            else
                param_tag = fmt("%s,'%s'", param_tag, val)
            end
        end
    end
    local sql = [[SELECT * FROM cluster_events where tag in (]]..param_tag..[[) AND current  >  %d AND current  <= %d  ORDER BY current ]]
    return self.db:exec(sql,{ min_at * 1000, max_at * 1000 })
end

function DAO:insert(tag, at, data)
    local sql = [[insert into cluster_events (tag, node_id, scope_id, data, current) values (%s, %s, %s, %s, %d)]]
    return self.db:exec(sql,{ tag, node.node_id, node.scope_id, data, at * 1000 })
end


return DAO

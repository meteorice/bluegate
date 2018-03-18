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

function DAO:getConfig()
    local sql = [[SELECT * FROM ratelimit where LIMIT_type = %s]]
    return self.db:exec(sql,{ 'ALL' })
end

function DAO:set_rate(rate)
    local sql = [[UPDATE ratelimit SET rate=%d WHERE LIMIT_TYPE=%s]]
    self.db:exec(sql,{ rate, 'ALL' })
end

function DAO:set_burst(burst)
    local sql = [[UPDATE ratelimit SET burst=%d WHERE LIMIT_TYPE=%s]]
    self.db:exec(sql,{ burst, 'ALL' })
end

return DAO

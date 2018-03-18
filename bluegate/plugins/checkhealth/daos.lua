require 'pl.text'.format_operator()
local util  = require 'bluegate.utils.util'
local node = require "bluegate.node"
local strx = require "pl.stringx"
local pretty  = require 'pl.pretty'
local class= require 'pl.class'

local nlog  = ngx.log
local err = ngx.ERR
local warn  = ngx.WARN
local info  = ngx.INFO
local debug = ngx.DEBUG
local fmt   = string.format

local DAO = class()

function DAO:_init(db)
    self.db = db
end

function DAO:logs(upstream,server,error)
    local sql = [[insert into down_log (upstream,server,description) values ( %s,%s,%s )]]
    self.db:exec(sql,{ upstream , server , error })
end

return DAO

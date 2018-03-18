local util  = require 'bluegate.utils.util'
local node = require "bluegate.node"
local pretty  = require 'pl.pretty'
local class= require 'pl.class'

local nlog  = ngx.log
local err = ngx.ERR
local warn  = ngx.WARN
local info  = ngx.INFO
local debug = ngx.DEBUG
local fmt   = string.format

return function(ALLDAO)
    local DAO = class(ALLDAO)

    function DAO:readcrm3Config()
        local sql ='select type,config from crm3_config where alive = 1'
        local res =  self.db:exec(sql)
        local map = {}
        for _, row in ipairs(res) do
            map[row.type] = row.config or ""
        end
        return map
    end

    return DAO
end

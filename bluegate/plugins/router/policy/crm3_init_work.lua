local ck = require "resty.cookie"
local pretty  = require 'pl.pretty'
local strx = require 'pl.stringx'
local List = require "pl.List"
local node = require "bluegate.node"
local util  = require 'bluegate.utils.util'
local len = string.len
local nlog  = ngx.log
local err = ngx.ERR
local warn  = ngx.WARN
local info  = ngx.INFO
local debug = ngx.DEBUG
local fmt   = string.format
local tremove = table.remove

_M = {}

local function transfLogic(value)
    if value == nil or not value or value == "" then
        return ""
    end
    if value == "&&" then
        return "and"
    end
    if value == "||" then
        return "or"
    end
    return value
end

function transfOpr(value)
    if value == "!=" then
        return "~="
    end
    return value
end

local function analyzeLine(str)
    --print("in=",str)
    local lines = {}
    --匹配"GRP==W && GT==P > W"这种字符串
    for all,key,opr,value,logic in string.gmatch(str,"(([^%s]+)%s*([=!]=)%s*([^%s]+)%s*([&|]*))") do
        --print("*",all," ",key," ",opr," ",value," ",logic)
        local logic2 = transfLogic(logic)
        local opr2 = transfOpr(opr)
        if not string.find(value,",") then
            local value2 = table.concat({"\"",value,"\""})
            table.insert(lines,table.concat({key,opr2,value2,logic2}," "))
        else
            --处理AREA==A1,A2,A3 这种 变成 (AREA=="A1" or AREA=="A2" or AREA=="A3")
            --处理AREA!=A1,A2,A3 这种 变成 (AREA~="A1" and AREA~="A2" and AREA~="A3")
            local relation = " or "
            if opr2 == "~=" then
                relation = " and "
            end
            local intb = {}
            local fs = strx.split(value,",")
            for k,v in ipairs(fs) do
                local value2 = table.concat({"\"",v,"\""})
                --一个逻辑块AREA=="A1"
                table.insert(intb,table.concat({key,opr2,value2}," "))
            end
            --组装成(AREA=="A1" or AREA=="A2" or AREA=="A3") [and/or]
            table.insert(lines,table.concat({"(",table.concat(intb,relation),")",logic2}))
        end
    end
    return table.concat(lines," ")
end

local function analyzeConfig(funname, args ,str)
    local it = strx.lines(str)
    local script = " return  function "..funname ..args.." \n"
    for line in it do
        if line and len(line) > 0 then
            if not string.find(line,"^[#%[].+") and not string.find(line,"RW") then
                local s,e = string.find(line,">")
                --找出规则段
                local str = string.sub(line,0,s-1)
                --找出结果
                local res = string.sub(line,s+1)
                --print("str=",str)
                local code_str = analyzeLine(str)
                if string.find(code_str,"^%s*$") ~= nil  then
                    script = script .. ("    return \"" .. util.trim(res) .. "\" \n")
                else
                    script = script .. "    if " .. code_str .." then "
                    script = script .. (" return \"".. util.trim(res) .. "\" end \n")
                end
            end
        end
    end
    script = table.concat({script,"end"})
    return script
end

-- 是否走缓存proxy
local function analyzeProxyCacheFile(funname,str)
    local it = strx.lines(str)
    local script = "function "..funname.." \n"
    script = script .. "\t local request_uri = ngx.var.request_uri \n"
    for line in it do
        if not string.find(line,"^[#%[].+")  then
            script = script .. "\t if string.find(request_uri,\"" .. line .. "\") then \n"
            script = script .. (" \t\t return true \n\t end \n")
        end
    end
    script = table.concat({script,"\t return false \n end"})
    return script
end

function _M.init_worker(self,worker_events)
    worker_events.register(function(data, event, source, pid)
        --loading crm3 route config
        local map = self.dao:readcrm3Config()

        local it = List {'domain;(APP)','area;(loginRegionId,DOMAIN)','in;(input,AREA,DOMAIN)',
        'gt;(APP,phoneNbr,staffCode,channelId,loginRegionId,AREA,IN,DOMAIN)',
        'rw;(sercode,AREA,IN,GT,DOMAIN)','grp;(IN,AREA,RW,GT,DOMAIN)','tag;(GT,GRP,AREA,IN,RW,DOMAIN)','itg;(TAG,DOMAIN)'}

        local fun = {}
        for v in it:iter() do
            local tmp = strx.split(v,';')
            local f = "f_"..tmp[1];
            local script = analyzeConfig("", tmp[2], map[tmp[1]])
            nlog(debug, util.green(script))
            local fun = assert(loadstring(script),tmp[1].."脚本有语法错误")()
            self[f] = fun
        end

    end, "crm3","refresh")

    util.once_init_work(function()
        worker_events.post_local("crm3","refresh",{})
    end)
    nlog(debug,"crm3--->init_worker")
end

return _M

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

-- 根据 {domain1:grp1;domain2:grp2;domain3:grp3} 取domain
local function getGrpByDomain(context_str,domain)
    --ngx.log(ngx.ERR,"===>",context_str,"   ddd= > ",domain)
    local str = util.trim(context_str)
    --ngx.log(ngx.ERR,"===>",context_str,"   ddd= > ",domain)
    if context_str == nil or context_str == "" then
        return nil
    end
    str = string.sub(str,2,string.len(str)-1)
    local fs = strx.split(str,";")
    for k,v in ipairs(fs) do
        --print("k=",k,",value=",v)
        local key,value = util.getPairsValue(v,":")
        if key == domain then
            return value
        end
    end
    return nil
end

--计算inst
local function getInst(self,res_grp,res_gt,res_area,res_in,res_rw,domain)
    local inst = "{"
    local context_str = res_grp
    local str = util.trim(context_str)
    if context_str == nil or context_str == "" then
        return "{}"
    end
    --去掉大括号
    str = string.sub(str,2,string.len(str)-1)
    local fs = strx.split(str,";")
    local len = #fs
    for index,v in ipairs(fs) do
        local domain,real_grp = util.getPairsValue(v,":")
        --ngx.log(ngx.ERR,"domain=",domain," ,real_grp=",real_grp)
        local res_tag = self.f_tag(res_gt,real_grp,res_area,res_in,res_rw,domain)
        --ngx.log(ngx.ERR,"res_tag=",res_tag)
        local res_itg = self.f_itg(res_tag,domain)
        --ngx.log(ngx.ERR,"res_itg=",res_itg)
        local inst_suffix = table.concat({real_grp,"_",res_itg})
        --ngx.log(ngx.ERR,"inst_suffix=",inst_suffix)
        inst = table.concat({inst,domain,":",inst_suffix})
        if index ~= len then
            inst = table.concat({inst,";"})
        end
    end
    inst = inst .. "}"
    return inst
end
--是否是服务地址
function isService()
	local request_uri = ngx.var.uri;
	--ngx.say("--access_by_lua_block--")
	if string.find(request_uri,"^/([^/]+)/service/") ~= nil then
		return true
	else
		return false
	end
end

function _M.router(self,config,inkey)
    local cookie, error = ck:new()
    if not cookie then
        nlog(err, error)
        return
    end
    local app = ngx.ctx.app
    local input=util.getHeaderCookies("input")
    local regionId=util.getHeaderCookies("loginRegionId")
    local phoneNbr=util.getHeaderCookies("phoneNbr")
    local staffCode=util.getHeaderCookies("staffCode")
    local channelId=util.getHeaderCookies("channelId")

    local servercode = ""
    local prefix = ""
    local request_uri = ngx.var.uri;
    if isService() == true then
        nlog(debug,"--remote_invoke-->",request_uri)
        prefix,servercode =  string.match(request_uri,"/(.+)/service/(.+)")
        ngx.req.set_uri("/service/"..servercode, false)
    end

    local domain = self.f_domain(app)
    local res_area = self.f_area(regionId,domain)
    local res_in = self.f_in(input,res_area,domain)
    local res_gt = self.f_gt(app,phoneNbr,staffCode,channelId,regionId,res_area,res_in,domain)
    local res_rw = self.f_rw(servercode,res_area,res_in,res_gt,domain)
    local res_grp = self.f_grp(res_in,res_area,res_rw,res_gt,domain)
    local real_grp = getGrpByDomain(res_grp,domain)
    local res_tag = self.f_tag(res_gt,real_grp,res_area,res_in,res_rw,domain)
    local res_itg = self.f_itg(res_tag,domain)

    local inst = getInst(self,res_grp,res_gt,res_area,res_in,res_rw,domain)

    nlog(debug," INST=",inst,"\n domain=",domain,"\n servercode=",servercode,"\n res_area=",res_area,"\n res_in=",res_in,"\n res_gt=",res_gt,"\n res_rw=",res_rw,"\n res_grp=",res_grp,"\n real_grp=",real_grp,"\n res_tag=",res_tag,"\n res_itg=",res_itg)
    if real_grp == nil then
        real_grp = "DEF"
    end
    proxy_name = fmt("%s_%s_%s",app,real_grp,res_itg)

    util.setHeader("INST",inst)
    util.setHeader("staffCode",staffCode)
    util.setHeader("loginRegionId",regionId)
    util.setHeader("channelId",channelId)
    util.setHeader("phoneNbr",phoneNbr)
    util.setHeader("input",input)
    util.setHeader("sercode",servercode)

    util.setHeader("AREA",res_area)
    util.setHeader("IN",res_in)
    util.setHeader("RW",res_rw)
    util.setHeader("GRP",res_grp)
    util.setHeader("TAG",res_tag)
    util.setHeader("ITG",res_itg)
    util.setHeader("GT",res_gt)

    if  res_grp == nil or res_itg == nil or string.find(res_grp,"^%s*$") or string.find(res_itg,"^%s*$") then
        nlog(debug,"res_grp,res_itg路由参数为空")
        proxy_name = table.concat({app,"_DEF_DEF"})
    end

    if proxy_name ~= nil then
        util.setHeader("CLUSTER_PROXYNAME",proxy_name)
        --util.add_cookie(table.concat({"PROXYNAME=",proxy_name,"; Path=/",app}))
    end
    nlog(debug,"crm3 router to [",proxy_name,"]")
    return proxy_name
end

return _M

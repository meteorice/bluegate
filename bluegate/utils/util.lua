local uuid = require "resty.jit-uuid"
uuid.seed()
local strx = require 'pl.stringx'
local find = string.find
local len  = string.len
local fmt   = string.format
local ngxlog=ngx.log
local STDERR = ngx.STDERR
local EMERG = ngx.EMERG
local ALERT = ngx.ALERT
local CRIT = ngx.CRIT
local ERR = ngx.ERR
local WARN = ngx.WARN
local NOTICE = ngx.NOTICE
local INFO = ngx.INFO
local DEBUG = ngx.DEBUG

local _M = {}

_M.uuid = uuid.generate_v4

function _M.load_module_if_exists(module_name)
    local status, res = pcall(require, module_name)
    if status then
        return true, res
-- Here we match any character because if a module has a dash '-' in its name, we would need to escape it.
    elseif type(res) == "string" and find(res, "module '" .. module_name .. "' not found", nil, true) then
        return false, res
    else
        error(res)
    end
end

function _M.isNull(str)
    if not str or len(str) == 0 then
        return true
    end
    return false
end

function _M.trim (s)
    if s == nil then
        return ""
    end
    return (string.gsub(s, "^%s*(.-)%s*$", "%1"))
end

function _M.getHeaderCookies(key)
    local header = ngx.req.get_headers()
    local var = ngx.var
    local value=var["cookie_"..key]
    if value == nil or value == '' then
        value = header[key]
    end
    return value
end

function _M.setHeader(key,value)
    --返回头
    local set_res_header = ngx.header
    --下一站请求头
    local set_req_header = ngx.req.set_header
    if value ~= nil and key ~= nil then
        set_res_header[key]=value
        set_req_header(key,value)
    end
end
function _M.getPairsValue(str,split)
    local map = strx.split(str,split)
    return map[1],map[2]
end
function _M.parse_url()
    local result = {}
    local request_uri = ngx.var.request_uri
    local index = string.find(request_uri, "?")
    if index then
        if ngx.var.args then
            result.request_args = {}
            for k, v in string.gmatch(ngx.var.args, "([^&]+)=([^&]+)") do
                result.request_args[k] = v
            end
        end
        request_uri = string.sub(request_uri, 1, index - 1)
    end
    local context_root_path = "/"
    if string.find(string.sub(request_uri, 2), context_root_path) ~= nil then
        result.context_path = context_root_path..string.match(request_uri, "([^/]+)")
    else
        result.context_path = context_root_path
    end
    result.request_path = string.sub(request_uri, string.len(result.context_path) + 1)
    return result
end

function _M.get_context_path()
    local request_uri = ngx.var.request_uri
    local index = string.find(request_uri, "?")
    if index then
        request_uri = string.sub(request_uri, 1, index-1)
    end
    local context_root_path = "/"
    if request_uri ~= context_root_path then
        return context_root_path..string.match(request_uri, "([^/]+)")
    else
        return context_root_path
    end
end

-- is array
function _M.isArray(arr)
    if not arr then
        return false
    end
    local i = 0
    for _ in pairs(arr) do
        i = i + 1
        if arr[i] == nil then
            return false
        end
    end
    return true
end
-- in the init_worker ,do once
function _M.once_init_work(func)
    local ok, error = ngx.timer.at(0, function (premature)
        if premature then
            return
        end
        func()
    end)
    if not ok then
        nlog(err, "[once_init_work] failed to create the timer: ", error)
        return
    end
end

function _M.global_once(func)
    if ngx.worker.id() == 0 then
        _M.once_init_work(func)
    end
end

local color = function(s,num)
    return fmt("\027[%dm%s\027[0m",num,s)
end
-- error , importance
function _M.red(s)
    return color(s,31)
end
-- config
function _M.green(s)
    return color(s,32)
end
-- sql
function _M.yellow(s)
    return color(s,33)
end
-- core
function _M.violet(s)
    return color(s,35)
end
-- other
function _M.blue(s)
    return color(s,36)
end

function _M.debug(...)
    ngxlog(DEBUG,...)
end

function _M.notice(...)
    ngxlog(NOTICE,...)
end

function _M.info(...)
    ngxlog(INFO,...)
end

function _M.warn(...)
    ngxlog(WARN,...)
end

function _M.err(...)
    ngxlog(ERR,...)
end

return _M

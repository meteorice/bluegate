local log = require "bluegate.cmd.log"
local kill = require "bluegate.cmd.kill"
local meta = require "bluegate.meta"
local pl_path = require "pl.path"
local pl_utils = require "pl.utils"
local fmt = string.format

local nginx_bin_name = "nginx"
local nginx_search_paths = {
    "/usr/local/nginx/sbin",
}
local nginx_version_pattern = "^nginx.-openresty.-([%d%.]+)"

local function send_signal(bluegate_conf, signal)
    local pidfile = pl_path.join(bluegate_conf.prefix,bluegate_conf.nginx_pid)
    if not kill.is_running(pidfile) then
        return nil, "nginx not running in prefix: " .. bluegate_conf.prefix
    end

    log.verbose("sending %s signal to nginx running at %s", signal, bluegate_conf.nginx_pid)

    local code = kill.kill(pidfile, "-s " .. signal)
    if code ~= 0 then
        return nil, "could not send signal"
    end

    return true
end

local _M = {}

function _M.find_nginx_bin()
    log.debug("searching for nginx executable")

    -- environment variables have highest
    local NGINX_HOME = os.getenv('NGINX_HOME')
    if NGINX_HOME ~= nil then
        return pl_path.join(NGINX_HOME,'sbin',nginx_bin_name)
    end

    local found
    for _, path in ipairs(nginx_search_paths) do
        local found = pl_path.join(path, nginx_bin_name)
    end

    if not found then
        return nil, "could not find  nginx executable. set environment variables 'NGINX_HOME'"
    end

    return found
end

function _M.start(bluegate_conf)
    local nginx_bin, err = _M.find_nginx_bin()
    if not nginx_bin then
        return nil, err
    end
    local pidfile = pl_path.join(bluegate_conf.prefix,bluegate_conf.nginx_pid)
    if kill.is_running(pidfile) then
        return nil, "nginx is already running in " .. bluegate_conf.prefix
    end

    local cmd = fmt("%s -p %s -c %s", nginx_bin, bluegate_conf.prefix, "nginx.conf")

    log.debug("starting nginx: %s", cmd)

    local ok, _, _, stderr = pl_utils.executeex(cmd)
    if not ok then
        return nil, stderr
    end

    log.debug("nginx started")

    return true
end

function _M.stop(bluegate_conf)
    return send_signal(bluegate_conf, "TERM")
end

function _M.quit(bluegate_conf, graceful)
    return send_signal(bluegate_conf, "QUIT")
end

function _M.reload(bluegate_conf)
    local pidfile = pl_path.join(bluegate_conf.prefix,bluegate_conf.nginx_pid)
    if not kill.is_running(pidfile) then
        return nil, "nginx not running in prefix: " .. bluegate_conf.prefix
    end

    local nginx_bin, err = _M.find_nginx_bin()
    if not nginx_bin then
        return nil, err
    end

    local cmd = fmt("%s -p %s -c %s -s %s", nginx_bin, bluegate_conf.prefix, "nginx.conf", "reload")

    log.debug("reloading nginx: %s", cmd)

    local ok, _, _, stderr = pl_utils.executeex(cmd)
    if not ok then
        return nil, stderr
    end

    return true
end

return _M

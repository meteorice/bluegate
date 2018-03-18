local prefix_handler = require "bluegate.cmd.prefix_handler"
local default_nginx_template = require "bluegate.cmd.templates.nginx"
local bluegate_nginx_template = require "bluegate.cmd.templates.nginx_bluegate"
local kill = require "bluegate.cmd.kill"
local nginx_signals = require "bluegate.cmd.nginx_signals"
local conf_loader = require "bluegate.cmd.conf_loader"
local pl_template = require "pl.template"
local pretty = require 'pl.pretty'
local pl_stringx = require "pl.stringx"
local pl_tablex = require "pl.tablex"
local pl_utils = require "pl.utils"
local pl_file = require "pl.file"
local pl_path = require "pl.path"
local pl_dir = require "pl.dir"
local log = require "bluegate.cmd.log"
local fmt = string.format


local function execute(args)
    local conf = assert(conf_loader(args.conf, {
        prefix = args.prefix
    }))
    log(pretty.write(conf))
    assert(not kill.is_running(conf.nginx_pid), "bluegate is already running in " .. conf.prefix)

    assert(prefix_handler.prepare_prefix(conf, args.nginx_conf))

    local err
    xpcall(function()
        assert(nginx_signals.start(conf))
        log("bluegate started")
    end, function(e)
        err = e -- cannot throw from this function
    end)

    if err then
        log.verbose("could not start bluegate, stopping services")
        pcall(nginx_signals.stop(conf))
        log.verbose("stopped services")
        error(err) -- report to main error handler
    end
end

local lapp = [[
Usage: bluegate start [OPTIONS]

Start bluegate (Nginx and other configured services) in the configured
prefix directory.

Options:
 -c,--conf        (optional string)   configuration file
 -p,--prefix      (optional string)   override prefix directory
 --nginx-conf     (optional string)   custom Nginx configuration template
]]

return {
  lapp = lapp,
  execute = execute
}

local nginx_signals = require "bluegate.cmd.nginx_signals"
local conf_loader = require "bluegate.cmd.conf_loader"
local pl_path = require "pl.path"
local log = require "bluegate.cmd.log"

local function execute(args, opts)
    opts = opts or {}

    log.disable()
    -- only to retrieve the default prefix or use given one
    local default_conf = assert(conf_loader(nil, {
        prefix = args.prefix
    }))
    log.enable()
    assert(pl_path.exists(default_conf.prefix), "no such prefix: " .. default_conf.prefix)

    if opts.quiet then
        log.disable()
    end

    local conf = assert(conf_loader(pl_path.join(default_conf.prefix,default_conf.bluegate_env)))
    assert(nginx_signals.stop(conf))

    if opts.quiet then
        log.enable()
    end

    log("bluegate stopped")
end

local lapp = [[
Usage: bluegate stop [OPTIONS]

Stop a running bluegate node (Nginx and other configured services) in given
prefix directory.

This command sends a SIGTERM signal to Nginx.

Options:
    -p,--prefix      (optional string) prefix bluegate is running at
]]

return {
    lapp = lapp,
    execute = execute
}

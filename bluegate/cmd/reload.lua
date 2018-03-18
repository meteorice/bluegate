local prefix_handler = require "bluegate.cmd.prefix_handler"
local nginx_signals = require "bluegate.cmd.nginx_signals"
local conf_loader = require "bluegate.cmd.conf_loader"
local pl_path = require "pl.path"
local log = require "bluegate.cmd.log"

local function execute(args)
    
    -- retrieve prefix or use given one
    local default_conf = assert(conf_loader(args.conf, {
        prefix = args.prefix
    }))

    assert(pl_path.exists(default_conf.prefix), "no such prefix: " .. default_conf.prefix)

    -- local conf = assert(conf_loader(pl_path.join(default_conf.prefix,default_conf.bluegate_env), {
    --     prefix = args.prefix
    -- }))
    assert(prefix_handler.prepare_prefix(default_conf, args.nginx_conf))

    assert(nginx_signals.reload(default_conf))
    log("bluegate reloaded")
end

local lapp = [[
Usage: bluegate reload [OPTIONS]

Reload a bluegate node (and start other configured services
if necessary) in given prefix directory.

This command sends a HUP signal to Nginx, which will spawn
new workers (taking configuration changes into account),
and stop the old ones when they have finished processing
current requests.

Options:
 -c,--conf        (optional string) configuration file
 -p,--prefix      (optional string) prefix bluegate is running at
 --nginx-conf     (optional string) custom Nginx configuration template
]]

return {
    lapp = lapp,
    execute = execute
}

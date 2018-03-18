local prefix_handler = require "bluegate.cmd.prefix_handler"
local default_nginx_template = require "bluegate.cmd.templates.nginx"
local bluegate_nginx_template = require "bluegate.cmd.templates.nginx_bluegate"
local kill = require "bluegate.cmd.kill"
local nginx_signals = require "bluegate.cmd.nginx_signals"
local conf_loader = require "bluegate.cmd.conf_loader"
local start = require "bluegate.cmd.start"
local stop = require "bluegate.cmd.stop"
local log = require "bluegate.cmd.log"

local function execute(args)
    local conf

    log.disable()

    if args.prefix then
        conf = assert(conf_loader(pl_path.join(args.prefix, ".bluegate_env")))

    else
        conf = assert(conf_loader(args.conf))
        args.prefix = conf.prefix
    end

    log.enable()

    pcall(stop.execute, args, { quiet = true })

    local tstart = os.time()
    local texp, running = tstart + 5 -- min 5s timeout
    local running
    repeat
        os.execute("sleep 0.2")
        running = kill.is_running(conf.nginx_pid)
    until not running or os.time() >= texp

    start.execute(args)
end

local lapp = [[
Usage: bluegate restart [OPTIONS]

Restart a bluegate node (and other configured services like Serf)
in the given prefix directory.

This command is equivalent to doing both 'bluegate stop' and
'bluegate start'.

Options:
 -c,--conf        (optional string)   configuration file
 -p,--prefix      (optional string)   prefix at which Kong should be running
 --nginx-conf     (optional string)   custom Nginx configuration template
]]

return {
    lapp = lapp,
    execute = execute
}

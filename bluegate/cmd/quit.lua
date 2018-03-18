local nginx_signals = require "bluegate.cmd.nginx_signals"
local conf_loader = require "bluegate.cmd.conf_loader"
local pl_path = require "pl.path"
local kill = require "bluegate.cmd.kill"
local log = require "bluegate.cmd.log"

local function execute(args)
    log.disable()
    -- retrieve default prefix or use given one
    local default_conf = assert(conf_loader(nil, {
        prefix = args.prefix
    }))
    log.enable()
    assert(pl_path.exists(default_conf.prefix), "no such prefix: " .. default_conf.prefix)

    local conf = assert(conf_loader(pl_path.join(default_conf.prefix,default_conf.bluegate_env)))

    assert(nginx_signals.quit(conf))

    log.verbose("waiting for nginx to finish processing requests")

    local tstart = os.time()
    local texp, running = tstart + math.max(args.timeout, 1) -- min 1s timeout
    repeat
        os.execute("sleep 0.2")
        running = kill.is_running(conf.nginx_pid)
    until not running or os.time() >= texp

    if running then
        log.verbose("nginx is still running at %s, forcing shutdown", conf.prefix)
        assert(nginx_signals.stop(conf))
        log("Timeout, bluegate stopped forcefully")
        return
    end

    log("bluegate stopped (gracefully)")
end

local lapp = [[
Usage: bluegate quit [OPTIONS]

Gracefully quit a running bluegate node (Nginx and other
configured services) in given prefix directory.

This command sends a SIGQUIT signal to Nginx, meaning all
requests will finish processing before shutting down.
If the timeout delay is reached, the node will be forcefully
stopped (SIGTERM).

Options:
    -p,--prefix      (optional string) prefix Kong is running at
    -t,--timeout     (default 10) timeout before forced shutdown
]]

return {
    lapp = lapp,
    execute = execute
}

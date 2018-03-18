local meta = require "bluegate.meta"
local pretty = require 'pl.pretty'

local lapp = [[
Usage: bluegate version [OPTIONS]

Print Bluegate's version. With the -a option, will print
the version of all underlying dependencies.

Options:
 -a,--all         get version of all dependencies
]]

local str = [[
Bluegate: %s
ngx_lua: v0.10.11 released
nginx: 1.13.8
Lua: 5.1
]]

local function execute(args)
  if args.all then
    print(string.format(str,
      meta._VERSION
    ))
  else
    print(meta._VERSION)
  end
end

return {
  lapp = lapp,
  execute = execute
}

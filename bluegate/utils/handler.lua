local pl_utils = require "pl.utils"
local pl_stringx = require "pl.stringx"
local config = require 'pl.config'
local pretty = require 'pl.pretty'

local function get_ulimit()
  local ok, _, stdout, stderr = pl_utils.executeex "ulimit -n"
  if not ok then
    return nil, stderr
  end
  local sanitized_limit = pl_stringx.strip(stdout)
  if sanitized_limit:lower():match("unlimited") then
    return 65536
  else
    return tonumber(sanitized_limit)
  end
end

local function gather_system_infos(compile_env)
  local infos = {}

  local ulimit, err = get_ulimit()
  if not ulimit then
    return nil, err
  end

  infos.worker_rlimit = ulimit
  infos.worker_connections = math.min(16384, ulimit)

  return infos
end

return {
    infos = gather_system_infos
}

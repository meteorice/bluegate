local ck = require "resty.cookie"

_M = {}

function _M.router(config,inkey)
    local cookie, error = ck:new()
    if not cookie then
        nlog(err, error)
        return
    end
    --取工号
    local staff_id, error = cookie:get(inkey)
    local cluster_name = config[staff_id]
    if not cluster_name then
        cluster_name = config["default"]
    end
    return cluster_name
end

return _M

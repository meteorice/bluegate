local nlog = ngx.log
local info = ngx.INFO
local err = ngx.ERR
local _M = {}

function _M.isInit()
    local cache = ngx.shared.cache
    local init, flags= cache:get("init")
    return init
end

function _M.up()
    local cache = ngx.shared.cache
    local success, err, forcible = cache:set("init",true)
    if not success then
        nlog(err, "the bluegate up fail ,",err)
    end
end

function _M.down()
    local cache = ngx.shared.cache
    local success, err, forcible = cache:set("init",false)
    if not success then
        nlog(err, "the bluegate up down ,",err)
    end
end

function _M.block()
    local init = _M.isInit()
    while( init ~= true )
    do
        init = _M.isInit()
        ngx.log(ngx.ERR,"init ....",init)
        ngx.sleep(0.5)
    end
end

return _M

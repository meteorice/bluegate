local class= require 'pl.class'
local util= require 'bluegate.utils.util'

local debug = util.debug

class.Plugin()

function Plugin:_init()
    self.name = "baseplugin"
end

function Plugin:get_name()
    return self.name
end

function Plugin:init_worker()
    debug("executing plugin \"", self._name, "\": init_worker")
end

function Plugin:balancer()
    debug("executing plugin \"", self._name, "\": balancer")
end

function Plugin:certificate()
    debug("executing plugin \"", self._name, "\": certificate")
end

function Plugin:rewrite()
    debug("executing plugin \"", self._name, "\": rewrite")
end

function Plugin:access()
    debug("executing plugin \"", self._name, "\": access")
end

function Plugin:header_filter()
    debug("executing plugin \"", self._name, "\": header_filter")
end

function Plugin:body_filter()
    debug("executing plugin \"", self._name, "\": body_filter")
end

function Plugin:log()
    debug("executing plugin \"", self._name, "\": log")
end

local _M = {}
    function _M.extend()
        return class(Plugin)
    end
return _M

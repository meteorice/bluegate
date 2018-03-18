local _LEVELS = {
  debug = 1,
  verbose = 2,
  info = 3,
  warn = 4,
  error = 5,
  quiet = 6
}

local _M = {
    levels = _LEVELS
}

local function log(...)
    ngx.log(...)
end

local n = setmetatable(_M,{
    __call = function(_, ...)
        log(_LEVELS.info,...)
    end,
  __index = function(t, key)
    if _LEVELS[key] then
      return function(...)
        log(_LEVELS[key], ...)
      end
    end
    return rawget(t, key)
  end
})

return n

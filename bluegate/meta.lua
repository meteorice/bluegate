local version = setmetatable({
  major = 0,
  minor = 0,
  patch = 1,
  --suffix = ""
}, {
  __tostring = function(t)
    return string.format("%d.%d.%d%s", t.major, t.minor, t.patch,
                         t.suffix and t.suffix or "")
  end
})

return {
  _NAME = "bluegate",
  _VERSION = tostring(version),
  _VERSION_TABLE = version,

  _DEPENDENCIES = {
    nginx = {"openresty/1.13.6."},
  }
}

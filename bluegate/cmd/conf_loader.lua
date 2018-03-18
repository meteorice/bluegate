local default_conf = require "bluegate.cmd.templates.env_defaults"
local log = require "bluegate.cmd.log"
local pl_stringio = require "pl.stringio"
local pl_stringx = require "pl.stringx"
local pl_pretty = require "pl.pretty"
local pl_config = require "pl.config"
local pl_file = require "pl.file"
local pl_path = require "pl.path"
local tablex = require "pl.tablex"

local homedir = pl_path.expanduser('~')

local DEFAULT_PATHS = {
    "bluegate.conf",
    homedir .. "/bluegate.conf",
    "/etc/bluegate/bluegate.conf",
    "/etc/bluegate.conf"
}

local function overrides(k, default_v, file_conf, arg_conf)
    local value
    -- default values have lowest priority
    if file_conf and file_conf[k] == nil then
        value = default_v == "NONE" and "" or default_v
    else
        value = file_conf[k]
    end

    -- environment variables have higher priority
    local env_name = "BLUEGATE_" .. string.upper(k)
    local env = os.getenv(env_name)
    if env ~= nil then
        log.debug('%s ENV found with "%s"', env_name, env)
        value = env
    end

    -- arg_conf have highest priority
    if arg_conf and arg_conf[k] ~= nil then
        value = arg_conf[k]
    end

    return value, k
end

function load(path, custom_conf)
    local s = pl_stringio.open(default_conf)
    local defaults, err = pl_config.read(s)
    s:close()
    if not defaults then
        return nil, "could not load default conf: " .. err
    end

    local from_file_conf = {}

    if path and not pl_path.exists(path) then
        return nil, "no file at: " .. path
    elseif not path then
        for _, default_path in ipairs(DEFAULT_PATHS) do
            if pl_path.exists(default_path) then
                path = default_path
                break
            end
            log.verbose("no config file found at %s", default_path)
        end
    end

    if not path then
        log.verbose("no config file, skipping loading")
    else
        local f, err = pl_file.read(path)
        if not f then
            return nil, err
        end

        log.verbose("reading config file at %s", path)
        local s = pl_stringio.open(f)
        from_file_conf, err = pl_config.read(s, {
            smart = false,
            list_delim = "_blank_"
        })
        s:close()
        if not from_file_conf then
            return nil, err
        end
    end

    local conf = tablex.pairmap(overrides, defaults, from_file_conf, custom_conf)

    conf = tablex.merge(conf, defaults)

    do
        local conf_arr = {}
        for k, v in pairs(conf) do
            conf_arr[#conf_arr+1] = k .. " = " .. pl_pretty.write(v, "")
        end

        table.sort(conf_arr)

        for i = 1, #conf_arr do
            log.debug(conf_arr[i])
        end
    end

    return setmetatable(conf, nil)
end

return setmetatable({
    load = load
},{
    __call = function(_, ...)
        return load(...)
    end
})

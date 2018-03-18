local util  = require 'bluegate.utils.util'
local node  = require "bluegate.node"
local eventdao   = require "bluegate.cluster_events.daos"
local ngxnow    = ngx.now
local nlog      = ngx.log
local NOTICE    = ngx.NOTICE
local DEBUG     = ngx.DEBUG
local WARN      = ngx.WARN
local ERR       = ngx.ERR
local INFO      = ngx.INFO
local insert    = table.insert
local max       = math.max
local fmt       = string.format
local timer_ev  = ngx.timer.every

local POLL_INTERVAL_LOCK_KEY = "cluster_events:poll_interval"
local POLL_RUNNING_LOCK_KEY  = "cluster_events:poll_running"
local CURRENT_AT_KEY         = "cluster_events:at"

local _init
local poll_handler

local _M = {}
local mt = { __index = _M }

function _M.new(opts)

    if _init then
        return error("bluegate.cluster_events was already instantiated")
    end

    if opts.poll_interval and type(opts.poll_interval) ~= "number" then
        return error("opts.poll_interval must be a number")
    end

    if opts.poll_offset and type(opts.poll_offset) ~= "number" then
        return error("opts.poll_offset must be a number")
    end

    if not opts.dao then
        return error("opts.dao is required")
    end

    local poll_interval = max(opts.poll_interval or 5, 0)
    local poll_offset   = max(opts.poll_offset   or 0, 0)

    local self = {
        shm           = ngx.shared.sys,
        events_shm    = ngx.shared.cluster_events,
        dao           = eventdao(node.dao),
        poll_interval = poll_interval,
        poll_offset   = poll_offset,
        polling       = false,
        tags          = {},
        callbacks     = {},
    }

    local ok, err = self.shm:safe_set(CURRENT_AT_KEY, ngxnow())
    if not ok then
        return nil, "failed to set 'at' in shm: " .. err
    end

    _init = true

    return setmetatable(self, mt)
end

function _M:broadcast(tag, data)
    if type(tag) ~= "string" then
        nlog(ERR,"[broadcast] tag must be a string")
        return nil, "tag must be a string"
    end

    if type(data) ~= "string" then
        nlog(ERR,"[broadcast] data must be a string")
        return nil, "data must be a string"
    end

    local ok, err = self.dao:insert(tag, ngxnow(), data)
    if not ok then
        return nil, err
    end

    return true
end

function _M:subscribe(tag, cb)
    if type(tag) ~= "string" then
        return error("tag must be a string")
    end

    if type(cb) ~= "function" then
        return error("callback must be a function")
    end

    if not self.callbacks[tag] then
        self.callbacks[tag] = { cb }
        insert(self.tags, tag)
    else
        insert(self.callbacks[tag], cb)
    end

    if not self.polling then
        local ok, err = timer_ev(self.poll_interval, poll_handler, self)
        if not ok then
          return nil, "failed to start polling timer: " .. err
        end

        self.polling = true
    end
end

local function get_lock(self)
    local ok, err = self.shm:safe_add(POLL_RUNNING_LOCK_KEY, true, max(self.poll_interval, 10))
    if not ok then
        if err ~= "exists" then
            nlog(ERR, "failed to acquire poll_running lock: ", err)
        else
            nlog(DEBUG, "failed to acquire poll_running lock: a worker still holds the lock")
            return false
        end
    end
    return true
end

local function poll(self)
    local min_at, err = self.shm:get(CURRENT_AT_KEY)
    if err then
        return nil, "failed to retrieve 'at' in shm: " .. err
    end
    if not min_at then
        return nil, "no 'at' in shm"
    end

    min_at = min_at - self.poll_offset - 0.001

    local max_at = ngxnow()

    nlog(DEBUG, "polling events from: ", min_at, " to: ", max_at)

    local rows = self.dao:getEventsByTag(self.tags, min_at, max_at)
    if rows and #rows > 0 then
        nlog(DEBUG,"[CURRENT_AT_KEY]", max_at)
        local ok, err = self.shm:safe_set(CURRENT_AT_KEY, max_at)
        if not ok then
            return nil, "failed to set 'at' in shm: " .. err
        end
    end
    for _, row in ipairs(rows) do
        if row.node_id ~= node.node_id then
            local ran, err = self.events_shm:get(row.id)
            if err then
                return nil, "failed to probe if event ran: " .. err
            end
            if not ran then
                nlog(DEBUG, "new event (tag: ", row.tag, ") data: ", row.data)
            end
            local exptime = self.poll_interval + self.poll_offset
            local ok, err = self.events_shm:set(row.id, true, exptime)
            if not ok then
                return nil, "failed to mark event as ran: " .. err
            end
            local cbs = self.callbacks[row.tag]
            if cbs then
                for j = 1, #cbs do
                    local ok, err = pcall(cbs[j], cjson.decode(row.data))
                    if not ok  then
                        nlog(ERR, "callback threw an error: ", err)
                    end
                end
            end
        end
    end
    return true
end

poll_handler = function(premature, self)
    if premature or not self.polling then
        return
    end

    if not get_lock(self) then
        return
    end

    -- single worker
    local pok, perr, error = pcall(poll, self)
    if not pok then
        nlog(ERR, "poll() threw an error: ", perr)
    elseif not perr then
        nlog(ERR, "failed to poll: ", error)
    end

    -- unlock
    self.shm:delete(POLL_RUNNING_LOCK_KEY)

end

return _M

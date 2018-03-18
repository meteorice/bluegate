return [[
bluegate_env = .bluegate_env
prefix = .
log_level = notice
nginx_pid = logs/nginx.pid
nginx_conf = nginx.conf
nginx_bluegate_conf = nginx-bluegate.conf
nginx_optimizations = true

NGINX_DAEMON = on
NGINX_WORKER_PROCESSES = auto
LOG_LEVEL = debug
UPSTREAM_KEEPALIVE = 60
PROXY_LISTEN = 0.0.0.0:8000
PROXY_ACCESS_LOG = logs/access.log
PROXY_ERROR_LOG = logs/error.log
CLIENT_BODY_BUFFER_SIZE = 8k
CLIENT_MAX_BODY_SIZE = 8k
LUA_SOCKET_POOL_SIZE = 30

ADMIN_LISTEN = 0.0.0.0:9900
ADMIN_ACCESS_LOG = logs/access.log
ADMIN_ERROR_LOG = logs/error.log

LUA_PACKAGE_PATH = ./?.lua;./?/init.lua;
LUA_PACKAGE_CPATH = NONE
]]

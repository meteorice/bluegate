return [[
charset UTF-8;

error_log $(PROXY_ERROR_LOG) $(LOG_LEVEL);

> if nginx_optimizations then
>-- send_timeout 60s;          # default value
>-- keepalive_timeout 75s;     # default value
>-- client_body_timeout 60s;   # default value
>-- client_header_timeout 60s; # default value
>-- tcp_nopush on;             # disabled until benchmarked
>-- proxy_buffer_size 128k;    # disabled until benchmarked
>-- proxy_buffers 4 256k;      # disabled until benchmarked
>-- proxy_busy_buffers_size 256k; # disabled until benchmarked
>-- reset_timedout_connection on; # disabled until benchmarked
> end

client_body_buffer_size $(CLIENT_BODY_BUFFER_SIZE);
client_max_body_size $(CLIENT_MAX_BODY_SIZE);
#proxy_ssl_server_name on;
underscores_in_headers on;

lua_package_path '$(LUA_PACKAGE_PATH);;';
lua_package_cpath '$(LUA_PACKAGE_CPATH);;';
lua_socket_pool_size $(LUA_SOCKET_POOL_SIZE);
lua_max_running_timers 4096;
lua_max_pending_timers 16384;
lua_shared_dict sys             5m;
lua_shared_dict rate            100m;
lua_shared_dict route           10m;
lua_shared_dict cache           10m;
lua_shared_dict locks           5m;
lua_shared_dict worker_events   5m;
lua_shared_dict cluster_events 5m;
lua_socket_log_errors off;

proxy_set_header Host $http_host;
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

init_by_lua_block {
    bluegate = require 'bluegate.init'
    bluegate.init()
}

init_worker_by_lua_block {
    bluegate.init_worker()
}

upstream bluegate_upstream {
    server 0.0.0.1;
    balancer_by_lua_block {
        bluegate.balancer()
    }
    keepalive $(UPSTREAM_KEEPALIVE);
}

server {
    listen $(PROXY_LISTEN)$(PROXY_PROTOCOL);
    error_page 400 404 408 411 412 413 414 417 /bluegate_error_handler;
    error_page 500 502 503 504 /bluegate_error_handler;

    access_log $(PROXY_ACCESS_LOG);
    error_log $(PROXY_ERROR_LOG) $(LOG_LEVEL);

    client_body_buffer_size $(CLIENT_BODY_BUFFER_SIZE);

    location / {
        set $upstream_scheme             '';
        set $upstream_uri                '';
        set $upstream_host               '';
        proxy_next_upstream     http_500 error timeout;

        rewrite_by_lua_block {
            bluegate.rewrite()
        }

        access_by_lua_block {
            bluegate.access()
        }

        header_filter_by_lua_block {
            bluegate.header_filter()
        }

        body_filter_by_lua_block {
            bluegate.body_filter()
        }

        log_by_lua_block {
            bluegate.log()
        }

        proxy_http_version 1.1;
        proxy_set_header   Host              $upstream_host;
        proxy_pass_header  Server;
        proxy_pass_header  Date;
        proxy_ssl_name     $upstream_host;
        proxy_pass $upstream_scheme://bluegate_upstream$upstream_uri;
    }

    location = /bluegate_error_handler {
        internal;
        content_by_lua_block {
            bluegate.handle_error()
        }
    }
}

server {
    listen $(ADMIN_LISTEN);
    server_name admin;
    client_max_body_size 10m;
    client_body_buffer_size 10m;

    access_log $(ADMIN_ACCESS_LOG);
    error_log $(ADMIN_ERROR_LOG) $(LOG_LEVEL);

    location / {
        default_type application/json;
        content_by_lua_block {
            local server = require("bluegate.api.server")
            server:run()
        }
        #content_by_lua_file 'lib/bluegate/api/main.lua';
    }

    location /nginx_status {
        stub_status on;
        access_log   off;
    }

    location /robots.txt {
        return 200 'User-agent: *\nDisallow: /';
    }
}

]]

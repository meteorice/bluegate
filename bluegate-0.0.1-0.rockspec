package = "bluegate"
version = "0.0.1-0"
source = {
   url = "git://github.com/meteorice/bluegate"
}
description = {
   homepage = "https://github.com/meteorice/bluegate",
   license = "Apache License 2.0"
}
dependencies = {
   "lua >= 5.1, < 5.2",
   "lua-resty-jit-uuid == 0.0.7",
   "penlight == 1.5.4",
   "lua-resty-worker-events == 0.3.1",
   "lua-cjson == 2.1.0-1"
}
build = {
   type = "builtin",
   modules = {
        ["bluegate.core"]                                ="bluegate/core.lua",
        ["bluegate.init"]                                ="bluegate/init.lua",
        ["bluegate.meta"]                                ="bluegate/meta.lua",
        ["bluegate.nlog"]                                ="bluegate/nlog.lua",
        ["bluegate.node"]                                ="bluegate/node.lua",
        ["bluegate.bylog"]                               ="bluegate/bylog.lua",
        ["bluegate.cluster_events"]                      ="bluegate/cluster_events.lua",

        ["bluegate.cluster_events.daos"]                 ="bluegate/cluster_events/daos.lua",

        ["bluegate.plugins.plugin"]                      ="bluegate/plugins/plugin.lua",

        ["bluegate.utils.handler"]                       ="bluegate/utils/handler.lua",
        ["bluegate.utils.status"]                        ="bluegate/utils/status.lua",
        ["bluegate.utils.util"]                          ="bluegate/utils/util.lua",

        ["bluegate.api.coreapi"]                         ="bluegate/api/coreapi.lua",
        ["bluegate.api.main"]                            ="bluegate/api/main.lua",
        ["bluegate.api.server"]                          ="bluegate/api/server.lua",

        ["bluegate.cmd.check"]                           ="bluegate/cmd/check.lua",
        ["bluegate.cmd.conf_loader"]                     ="bluegate/cmd/conf_loader.lua",
        ["bluegate.cmd.init"]                            ="bluegate/cmd/init.lua",
        ["bluegate.cmd.kill"]                            ="bluegate/cmd/kill.lua",
        ["bluegate.cmd.log"]                             ="bluegate/cmd/log.lua",
        ["bluegate.cmd.nginx_signals"]                   ="bluegate/cmd/nginx_signals.lua",
        ["bluegate.cmd.prefix_handler"]                  ="bluegate/cmd/prefix_handler.lua",
        ["bluegate.cmd.quit"]                            ="bluegate/cmd/quit.lua",
        ["bluegate.cmd.reload"]                          ="bluegate/cmd/reload.lua",
        ["bluegate.cmd.restart"]                         ="bluegate/cmd/restart.lua",
        ["bluegate.cmd.start"]                           ="bluegate/cmd/start.lua",
        ["bluegate.cmd.stop"]                            ="bluegate/cmd/stop.lua",
        ["bluegate.cmd.templates.env_defaults"]          ="bluegate/cmd/templates/env_defaults.lua",
        ["bluegate.cmd.templates.nginx"]                 ="bluegate/cmd/templates/nginx.lua",
        ["bluegate.cmd.templates.nginx_bluegate"]        ="bluegate/cmd/templates/nginx_bluegate.lua",
        ["bluegate.cmd.version"]                         ="bluegate/cmd/version.lua",

        ["bluegate.dao.db.base"]                         ="bluegate/dao/db/base.lua",
        ["bluegate.dao.dbsql"]                       	 ="bluegate/dao/db/luasql.lua",
        ["bluegate.dao.db.mysql"]                        ="bluegate/dao/db/mysql.lua",
        ["bluegate.dao.factory"]                         ="bluegate/dao/factory.lua",
        ["bluegate.dao.sql.mysql"]                       ="bluegate/dao/sql/mysql.lua",

        ["bluegate.plugins.checkhealth.daos"]            ="bluegate/plugins/checkhealth/daos.lua",
        ["bluegate.plugins.checkhealth.db.mysql"]        ="bluegate/plugins/checkhealth/db/mysql.lua",
        ["bluegate.plugins.checkhealth.handler"]         ="bluegate/plugins/checkhealth/handler.lua",

        ["bluegate.plugins.logkafka.handler"]            ="bluegate/plugins/logkafka/handler.lua",

        ["bluegate.plugins.rate_limiting.api"]           ="bluegate/plugins/rate_limiting/api.lua",
        ["bluegate.plugins.rate_limiting.daos"]          ="bluegate/plugins/rate_limiting/daos.lua",
        ["bluegate.plugins.rate_limiting.db.mysql"]      ="bluegate/plugins/rate_limiting/db/mysql.lua",
        ["bluegate.plugins.rate_limiting.handler"]       ="bluegate/plugins/rate_limiting/handler.lua",

        ["bluegate.plugins.router.api"]                  ="bluegate/plugins/router/api.lua",
        ["bluegate.plugins.router.daos"]                 ="bluegate/plugins/router/daos.lua",
        ["bluegate.plugins.router.db.mysql"]             ="bluegate/plugins/router/db/mysql.lua",
        ["bluegate.plugins.router.handler"]              ="bluegate/plugins/router/handler.lua",
        ["bluegate.plugins.router.policy.crm3"]          ="bluegate/plugins/router/policy/crm3.lua",
        ["bluegate.plugins.router.policy.crm3_api"]      ="bluegate/plugins/router/policy/crm3_api.lua",
        ["bluegate.plugins.router.policy.crm3_daos"]     ="bluegate/plugins/router/policy/crm3_daos.lua",
        ["bluegate.plugins.router.policy.crm3_init_work"]="bluegate/plugins/router/policy/crm3_init_work.lua",
        ["bluegate.plugins.router.policy.staff"]         ="bluegate/plugins/router/policy/staff.lua",

        ["bluegate.plugins.sys.api"]                     ="bluegate/plugins/sys/api.lua",
        ["bluegate.plugins.sys.daos"]                    ="bluegate/plugins/sys/daos.lua",
        ["bluegate.plugins.sys.handler"]                 ="bluegate/plugins/sys/handler.lua",
   }
}

local cjson = require "cjson";

local config = ngx.shared.config;

local file = io.open("/var/eshop/install/csm_config.json", "r");
local content = cjson.decode(file:read("*all"));
file:close();

for name, value in pairs(content) do
    config:set(name, value);
end

etcd_server = config:get("ETCD_ENDPOINTS")
base_path = "/v2/keys"
suid = config:get("SU_ID")

global_setting_eshop_path = "/config/globalsetting/Eshop"
global_setting_proxy_path = "/config/globalsetting/Proxy"
global_setting_landscape_path = "/config/globalsetting/Landscape"
global_setting_storage_path = "/config/globalsetting/Storage"
downtime_path = "/config/downtime"
database_path = "/config/database/"
occ_path = "/config/serviceunit/" .. suid .. "/realservice/OCC/info"
eshop_admin_path = "/config/ESHOPADMIN"
idp_path = "/config/service/IDP/info"
eshopservice_path = "/config/"
local etcd_client = require "lua_etcd_resty"
local resty_lock = require "resty.lock"
local json = require("cjson")
local cache = ngx.shared.etcd_cache
local config_cache = ngx.shared.config

local write_lock = "write_lock"
local eclient = etcd_client:new()

local function tprint (tbl, indent)
    if not indent then indent = 0 end
    for k, v in pairs(tbl) do
        formatting = string.rep("  ", indent) .. k .. ": "
        if type(v) == "table" then
            print(formatting)
            tprint(v, indent+1)
        elseif type(v) == 'boolean' then
            print(formatting .. tostring(v))
        else
            print(formatting .. v)
        end
    end
end

local function get_value(is_get, path)
    local val, err = cache:get(path)
    if val then
        return val
    end

    if err then
        return
    end

    local lock = resty_lock:new("etcd_lock")
    local elapsed, err = lock:lock(write_lock)
    if not elapsed then
        ngx.log(ngx.ERR, "fail to acquire write lock : ", err)
        return
    end

    val, err = cache:get(path)
    if val then
        local ok, err = lock:unlock()
        if not ok then
            ngx.log(ngx.ERR, "fail to unlock write lock : ", err)
            return
        end

        return val
    end

    ngx.log(ngx.INFO, "get value from etcd, path : ", path)

    -- update the shm cache with the newly fetched value
    local ret, err = nil
    if is_get then
        ret, err = eclient:get(etcd_server .. base_path .. path)
    else
        ret, err = eclient:list(etcd_server .. base_path .. path)
    end
    if err and path ~= downtime_path then
        ngx.log(ngx.ERR, "fail to get value from etcd : ", err)
        ret = ""
    elseif err and path == downtime_path then
        ret = "no-data"
    end

    ngx.log(ngx.INFO, "get config from etcd : ", ret)

    local ok, err = cache:set(path, ret)
    if not ok then
        local ok, err = lock:unlock()
        if not ok then
            ngx.log(ngx.ERR, "fail to unlock write lock : ", err)
            return
        end

        ngx.log(ngx.ERR, "fail to set value to cache : ", err)
        return
    end

    local ok, err = lock:unlock()
    if not ok then
        ngx.log(ngx.ERR, "fail to unlock write lock : ", err)
        return
    end

    return ret
end

local global_setting_eshop_value = get_value(false, global_setting_eshop_path)
local global_setting_proxy_value = get_value(false, global_setting_proxy_path)
local global_setting_landscape_value = get_value(false, global_setting_landscape_path)
local global_setting_storage_value = get_value(false, global_setting_storage_path)
local downtime_value = get_value(false, downtime_path)
local database_value = get_value(false, database_path)
local occ_value = get_value(true, occ_path)
local eshop_admin_value = get_value(true, eshop_admin_path)
local idp_value = get_value(true, idp_path)
local eshop_id = ngx.req.get_headers()['X-ESHOP-ID']
if eshop_id then
    eshop_value = get_value(true, eshopservice_path .. "/eshop" .. eshop_id)
end

ngx.req.set_header('x-globalsetting-eshop', global_setting_eshop_value)
ngx.req.set_header('x-globalsetting-proxy', global_setting_proxy_value)
ngx.req.set_header('x-globalsetting-landscape', global_setting_landscape_value)
ngx.req.set_header('x-globalsetting-storage', global_setting_storage_value)
ngx.req.set_header('x-downtime', downtime_value)
ngx.req.set_header('x-database', database_value)
ngx.req.set_header('x-occ', occ_value)
ngx.req.set_header('x-eshopadmin', eshop_admin_value)
ngx.req.set_header('x-idp', idp_value)
if eshop_value then
    ngx.req.set_header('x-eshop', eshop_value)
end
local resty_lock = require "resty.lock"
local json = require("cjson")
local etcd_client = require "lua_etcd_resty"

local cache = ngx.shared.etcd_cache
local watch_key = "watch_key"
local watch_lock = "watch_lock"
local write_lock = "write_lock"
local eclient = etcd_client:new()
local watch_path = "/v2/keys/config"

local eshop_related_paths = {
    global_setting_eshop_path,
    global_setting_proxy_path,
    global_setting_landscape_path,
    global_setting_storage_path,
    downtime_path,
    database_path,
    occ_path,
    eshop_admin_path,
    idp_path,
    eshopservice_path}

local function watch_etcd(premature, lastmodifyindex)
    local delay = 0

    local modifyindex = nil
    if lastmodifyindex then
        modifyindex = lastmodifyindex
    else
        modifyindex = eclient:get_index(etcd_server .. watch_path)
    end

    local ret, err = eclient:watch(etcd_server .. watch_path, modifyindex)
    if err and err == "error" then
        delay = 5
    elseif ret then
        modifyindex = tonumber(ret["node"]["modifiedIndex"]) + 1
        ngx.log(ngx.INFO, "watch a change : " , json.encode(ret))
        for k,path in pairs(eshop_related_paths) do
            if string.find(ret["node"]["key"], path) then
                ngx.log(ngx.INFO, "lose efficacy data , etcd path : " , ret["node"]["key"], " cache key :", path)

                local lock = resty_lock:new("etcd_lock")
                local elapsed, err = lock:lock(write_lock)
                if not elapsed then
                    ngx.log(ngx.ERR, "fail to acquire write lock : ", err)
                    break
                end

                local ok, err = cache:set(path, nil)
                if not ok then
                    local ok, err = lock:unlock()
                    if not ok then
                        ngx.log(ngx.ERR, "fail to unlock write lock : ", err)
                        break
                    end

                    ngx.log(ngx.ERR, "fail to set value to cache : ", err)
                    break
                end

                local ok, err = lock:unlock()
                if not ok then
                    ngx.log(ngx.ERR, "fail to unlock write lock : ", err)
                    break
                end

            end
        end
    end

    local ok, err = ngx.timer.at(delay, watch_etcd, modifyindex)
    if not ok then
        ngx.log(ngx.ERR, "failed to create the watch_etcd timer: ", err)
        return
    end
end
-- step 1:
local val, err = cache:get(watch_key)
if val then
    ngx.log(ngx.INFO, "already have a watcher : ", val)
    return
end

if err then
    ngx.log(ngx.ERR, "fail to get watcher key : ", err)
    return
end

-- cache miss!
-- step 2:
local lock = resty_lock:new("etcd_lock")
local elapsed, err = lock:lock(watch_lock)
if not elapsed then
    ngx.log(ngx.ERR, "fail to acquire watch lock : ", err)
    return
end

-- lock successfully acquired!

-- step 3:
-- someone might have already put the value into the cache
-- so we check it here again:
val, err = cache:get(watch_key)
if val then
    local ok, err = lock:unlock()
    if not ok then
        ngx.log(ngx.ERR, "fail to unlock watch lock : ", err)
        return
    end

    ngx.log(ngx.INFO, "already have a watcher: ", val)
    return
end

--- step 4:
ngx.log(ngx.INFO, "start watcher thread: ", ngx.worker.pid())
ngx.timer.at(0, watch_etcd)

-- update the shm cache with the newly fetched value
local ok, err = cache:set(watch_key, ngx.worker.pid())
if not ok then
    local ok, err = lock:unlock()
    if not ok then
        ngx.log(ngx.ERR, "fail to unlock watch lock : ", err)
        return
    end

    ngx.log(ngx.ERR, "fail to update watch_key cache : ", err)
    return
end

local ok, err = lock:unlock()
if not ok then
    ngx.log(ngx.ERR, "fail to unlock watch lock : ", err)
    return
end

ngx.log(ngx.INFO, "My worker have a watcher: ")
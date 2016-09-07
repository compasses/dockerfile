local http = require "resty.http"
local json = require("cjson")

local ok, new_tab = pcall(require, "table.new")
if not ok or type(new_tab) ~= "function" then
    new_tab = function (narr, nrec) return {} end
end


local _M = new_tab(0, 155)
_M._VERSION = '0.01'

local mt = { __index = _M }

function _M.get(self, url)
    local params = {
        method = "GET",
        headers = {
            ["Accept-Language"] = "en-US,en;q=0.5",
            ["Accept-Encoding"] = "gzip, deflate",
            ["User-Agent"] = "Mozilla/5.0 (Windows NT 6.1; WOW64; rv:20.0) Gecko/20100101 Firefox/20.0",
            ["Accept"] = "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8"
        }
    }

    local httpc = http:new()
    httpc:set_timeout(1000)
    ngx.log(ngx.INFO, "send request :", url);

    local res, err = httpc:request_uri(url, params)
    if not res then
        ngx.log(ngx.ERR, "failed to request: ", err)
        return nil, "request error"
    end

    if res.status == 200 then
        bodyjson = json.decode(res.body)

        if bodyjson["errorCode"] then
            ngx.log(ngx.ERR, "get errorCode from etcd", bodyjson['errorCode'])
            return nil, bodyjson['errorCode']
        end

        return bodyjson['node']['value']
    else
        return res, "response code invalid"
    end
end

function _M.get_index(self, url)
    local params = {
        method = "GET",
        headers = {
            ["Accept-Language"] = "en-US,en;q=0.5",
            ["Accept-Encoding"] = "gzip, deflate",
            ["User-Agent"] = "Mozilla/5.0 (Windows NT 6.1; WOW64; rv:20.0) Gecko/20100101 Firefox/20.0",
            ["Accept"] = "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8"
        }
    }

    local httpc = http:new()
    httpc:set_timeout(5000)
    ngx.log(ngx.INFO, "send request :", url);

    local res, err = httpc:request_uri(url, params)
    if not res then
        ngx.log(ngx.ERR, "failed to request: ", err)
        return nil, "request error"
    end

    if res then
        return res.headers["x-etcd-index"]
    end
end

function _M.watch(self, url, modifyindex)
    local params = {
        method = "GET",
        headers = {
            ["Accept-Language"] = "en-US,en;q=0.5",
            ["Accept-Encoding"] = "gzip, deflate",
            ["User-Agent"] = "Mozilla/5.0 (Windows NT 6.1; WOW64; rv:20.0) Gecko/20100101 Firefox/20.0",
            ["Accept"] = "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8"
        }
    }

    local requestUrl = url .. "?wait=true&recursive=true"
    if modifyindex then
        requestUrl = requestUrl .. "&waitIndex=" .. modifyindex
    end

    ngx.log(ngx.ERR, "send request :", requestUrl);
    local httpc = http:new()
    httpc:set_timeout(300000)

    local res, err = httpc:request_uri(requestUrl, params)
    if err and err == "timeout" then
        ngx.log(ngx.INFO, "no change occurs: ")
        return nil, "timeout"
    elseif not res or res.status ~= 200 then
        ngx.log(ngx.ERR, "failed to request: ", err)
        return nil, "error"
    end

    if res then
        bodyjson = json.decode(res.body)

        if bodyjson["errorCode"] then
            ngx.log(ngx.ERR, "get errorCode from etcd", bodyjson['errorCode'])
        end

        return bodyjson
    end
end


function _M.list(self, url)
    local params = {
        method = "GET",
        headers = {
            ["Accept-Language"] = "en-US,en;q=0.5",
            ["Accept-Encoding"] = "gzip, deflate",
            ["User-Agent"] = "Mozilla/5.0 (Windows NT 6.1; WOW64; rv:20.0) Gecko/20100101 Firefox/20.0",
            ["Accept"] = "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8"
        }
    }

    local httpc = http:new()
    httpc:set_timeout(1000)
    ngx.log(ngx.INFO, "send request :", url);

    local res, err = httpc:request_uri(url, params)
    if not res then
        ngx.log(ngx.ERR, "failed to request: ", err)
        return nil, "request error"
    end

    if res.status == 200 then
        bodyjson = json.decode(res.body)

        if bodyjson["errorCode"] then
            ngx.log(ngx.ERR, "get errorCode from etcd", bodyjson["errorCode"])
            return nil, bodyjson['errorCode']
        end

        local node_list = bodyjson['node']['nodes']
        local ret = {}
        for k,v in pairs(node_list) do
            local path, leaf = v["key"]:match'(.*/)(.*)'
            ret[leaf] = v["value"]
        end

        return json.encode(ret)
    else
        return res, "response code invalid"
    end
end

function _M.new(self, opts)
    opts = opts or {}

    return setmetatable({opts = opts }, mt)
end


return _M

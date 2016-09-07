#!/usr/bin/env bash
if [ -f "/usr/local/openresty/nginx/logs/nginx.pid" ]; then
    /usr/local/openresty/nginx/sbin/nginx  -t
    /usr/local/openresty/nginx/sbin/nginx  -s reload
else
    /usr/local/openresty/nginx/sbin/nginx  -t -c /usr/local/openresty/nginx/openresty-app/config/nginx.conf
    /usr/local/openresty/nginx/sbin/nginx  -c /usr/local/openresty/nginx/openresty-app/config/nginx.conf
fi
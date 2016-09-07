# docker for eshop running container(docker scale)
#
# VERSION 0.0.1

FROM compasses/eshop_nginx:v1

MAINTAINER "Jet He"

# default ENV vars, can be overwritten by docker run -e "xxx"
ENV LOG_CONFIG_FILE=/var/www/eshop/wp-content/plugins/anywherecommerce/log-config-linux.json \
    ESHOP_CACHE_DIR=/var/eshop/cache/ \
    LOG_PATH=/opt/sap/log \
    ESHOP_THEME_LOCATION=templates

COPY fpm /etc/php/7.0/fpm/
COPY install/* /var/eshop/install/
ADD settings /var/eshop/settings

# config file for the db info to run wp-cli, ADD to an existing file will cause the file deleted!
#COPY wp-config-ci.php /var/www/eshop/wp-config.php

COPY supervisord-eshop.conf /etc/supervisor/conf.d/supervisord.conf

COPY .htaccess /var/www/eshop/.htaccess

# copy openresty related configurations
COPY openresty-app/ /usr/local/openresty/nginx/openresty-app/

RUN apt-get install jq -y --force-yes

# replace new wp-content
# add required permissions
RUN mv /usr/local/openresty/nginx/openresty-app/restylib/* /usr/local/openresty/lualib/resty/ \
    && mv /usr/local/openresty/nginx/openresty-app/conf/nginx.conf /usr/local/openresty/nginx/conf/nginx.conf \
    && rm -rf /var/www/eshop/wp-content \
    && rm -rf /var/eshop/build \
    && chmod +x /var/eshop/install/*.sh \
    && rm /var/eshop/install/wp-content.zip
    
RUN unzip -oq /var/eshop/install/build.zip -d /var/eshop/; exit 0 \
    && rm /var/eshop/install/build.zip

CMD ["/var/eshop/install/setup_eshop.sh"]

# eshop docker base image with apache php wordpress,  without mysql 
#
# VERSION 0.0.1

# TODO: replace with a ubuntu image, not use ubuntu:14.10
#FROM 10.58.113.37:5000/base_master/ubuntu:15.10
FROM ubuntu:15.10
MAINTAINER Jet He "gnhe2009@gmail.com"

# TODO: just to avoid default archive.ubuntu.com too slowly...
#RUN echo "deb http://mirrors.sohu.com/ubuntu/ trusty main restricted universe multiverse" >> /etc/apt/sources.list
COPY conf/sources.list /etc/apt/sources.list
COPY conf/apt.conf /etc/apt/apt.conf

## update and install libs ( install php5-curl to fix 60s waiting for some occ http request. ), 
## install sshpass to ssh run cmd in mysql server instead of using  mysql-client-core-5.5 (which causes docker build issue sometimes).
# removed  pwgen php-apc,  php5-mcrypt && php5enmod mcrypt 
# temp not use php5=5.5.9+dfsg-1ubuntu4.6, as latest 5.5.9+dfsg-1ubuntu4.7?
# weChat QR code lib depends on PHP GD library
RUN export https_proxy=http://proxy.pal.sap.corp:8080 &&\
    export http_proxy=http://proxy.pal.sap.corp:8080 &&\
    export no_proxy=10.* &&\
    apt-get update &&\
	apt-get install -y vim apache2 curl unzip php5 libapache2-mod-php5 php5-mysql php5-redis openssh-server supervisor  php5-curl mariadb-client php5-mcrypt php-apc  php5-gd &&\ 
	rm -rf /var/lib/apt/lists/*

# install php5-mcrypt
RUN php5enmod mcrypt

# enable apache rewrite; remove apache server default index file; and make writable; enable ssh by root; enable ssl;
# change docker system timezone to be same as CI env(PRC/GMT+8), for debug use. (TODO: remove it when deploy)
# remove timezone adjustment: cp /usr/share/zoneinfo/PRC /etc/localtime , for WP post case.
# enable mod_headers for set some header in apache config
RUN a2enmod rewrite	\ 
	&& rm /var/www/html/index.html \
	&& mkdir -p /var/run/sshd \
	&& echo 'root:12345' | chpasswd \
	&& sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config	\
	&& mkdir -p /etc/apache2/ssl/certs \
	&& a2enmod ssl \
    && a2enmod headers \
    && echo 'ServerSignature Off' >> /etc/apache2/apache2.conf  \
    && echo 'ServerTokens Prod' >> /etc/apache2/apache2.conf  \
    && a2enmod cache \
    && a2enmod cache_disk

# use cert for *.pvgl.sap.corp  
#	&& /usr/sbin/make-ssl-cert /usr/share/ssl-cert/ssleay.cnf /etc/apache2/ssl/localhost.pem 
COPY conf/sapanywhere.sap.corp.crt /etc/apache2/ssl/sapanywhere.sap.corp.crt
COPY conf/sapanywhere.sap.corp.key /etc/apache2/ssl/sapanywhere.sap.corp.key
	

# config to enable .htaccess and DocumentRoot to /var/www/eshop
COPY conf/apache-default /etc/apache2/sites-available/000-default.conf

# config to enable apache cache disk
COPY conf/cache_disk.conf /etc/apache2/mods-available/cache_disk.conf

# disable ssl in apache
RUN sed -i -e 's/\<SSLProtocol\ all/&\  -SSLv2 -SSLv3/' /etc/apache2/mods-available/ssl.conf

COPY conf/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# change docker DNS server
# NOTE: there's error to change /etc/resolv.conf: Device or resource busy, as no --privileged, refer to http://blog.docker.com/category/docker-releases/
# You can edit /etc/hosts, /etc/hostname and /etc/resolve.conf in a running container, 
# RUN sed -i '1s/^/nameserver 10.58.32.64\nnameserver 10.58.32.32\n/g' /etc/resolv.conf
# use copy file   also not work. COPY conf/resolv.conf  /etc/resolv.conf
# solution: replace dns file after container runs
#COPY conf/resolv.conf  /var/www/install/resolv.conf


# copy wordpress files (4.0, src changed, no eshop plugins), 
# echo.test is for user domain binding testing
COPY conf/occ-eshop.zip /var/www/install/occ-eshop.zip
RUN unzip -oq /var/www/install/occ-eshop.zip -d /var/www/eshop/  \
		&& rm /var/www/install/occ-eshop.zip  \
        && rm /var/www/eshop/readme.html \ 
        && rm /var/www/eshop/license.txt \
        && touch /var/www/eshop/echo.test 
		
## DO not  make wordpress upload folder, otherwise upload file will fail! (WP will auto create it .)
# RUN mkdir -p /var/www/eshop/wp-content/uploads \
#		&& chmod +w /var/www/eshop/wp-content/uploads 


EXPOSE 80 443 22

CMD ["/usr/bin/supervisord"]


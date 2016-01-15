FROM ubuntu:15.10

MAINTAINER Jet He "gnhe2009@gmail.com"

COPY sources.list /etc/apt/sources.list
COPY apt.conf /etc/apt/apt.conf
COPY resolv.conf /etc/resolv.conf

RUN echo nameserver 10.58.32.32 > /etc/resolv.conf

ENV http_proxy http://proxy.sin.sap.corp:8080
ENV https_proxy http://proxy.sin.sap.corp:8080

#RUN apt-get update
#RUN apt-get install -y nginx

#RUN echo 'Hi, I am in your container' \
#	> /usr/share/nginx/html/index.html
EXPOSE 80

#!/bin/bash

eshop_base_image="base_master/ubuntu_14.10lts_apache_wp"

# build base image using base image Dockerfile.
# If do not want to use the cache, use the --no-cache=true option
docker build -t $eshop_base_image .


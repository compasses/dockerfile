docker run -d -it --cap-add SYS_PTRACE --security-opt apparmor:unconfined -v /Users/i311352/AnyWhere/eshop/occ-eshop:/var/www/eshop -v /Users/i311352/AnyWhere/docker/eshop_logs:/opt/sap/log -p 443:443 -p 80:80 --dns 10.58.32.32 --dns 10.58.113.63 --dns 10.58.113.75 --dns-search pvgl.sap.corp --restart always --name eshop compasses/shop_resty


PROJECT := centos ubuntu nginx
.phony: all ${PROJECT} du

all: ${PROJECT}

centos:
	@echo "Centos Mirror"
	@wget -p -r -l 2 -k -K -N http://mirrors.sohu.com/centos; true

ubuntu:
	@echo "Ubuntu Mirror"
	@wget -p -r -l 2 -k -K -N http://mirrors.163.com/ubuntu-releases; true

nginx:
	@echo "Nginx Mirror"
	@wget -p -r -l 2 -k -K -N http://mirrors.sohu.com/nginx; true
	

du:
	@for a in *; do du -sh $$a; done
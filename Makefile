#=============================================================================
# requirement packages:  sudo , make
#
#=============================================================================
SHELL		= /bin/bash
WDIR		= $(shell pwd)
PWDIR           = $(shell cd .. ; pwd)
UID		= $(shell id -u)
#=============================================================================
INDOCKER      	= $(shell ls -al /.dockerenv 2>/dev/null|wc -l)
#=============================================================================
# Docker environment
# build host docker MUSHT work @ HOST
ifeq ($(INDOCKER),1)
all:
	@echo
	@echo "[ERR ] build host can't work in docker" 
	@echo
bct:
	@echo "bct = bct"
else
#=============================================================================
# HOST environment
#-----------------------------------------------------------------------------
DOCKERYAML     = $(WDIR)/docker-compose.yaml
DOCKERNAME     = $(USER)_bct_build
#-----------------------------------------------------------------------------
#DEBS           = build-essential vim joe git pv pbzip2 docker-compose sudo \
#			u-boot-tools file zip smbclient
DEBS           = vim joe make git pv pbzip2 docker-compose sudo \
			u-boot-tools file zip smbclient
#-----------------------------------------------------------------------------
all: check dockercomposeyam docker
#-----------------------------------------------------------------------------
check:
	@if [ `dpkg -l|grep docker-compose|grep "ii"|wc -l` -eq "0" ] ; then \
		sudo apt update -y ; sudo apt install -y docker-compose ; \
	fi
	@if [ "$(UID)" -eq "0" ] ; then \
		echo ; \
		echo "[INFO] UID = 0 , exit" ; \
		echo ; \
		exit 127; \
	fi
#-----------------------------------------------------------------------------
dockercomposeyam:
	@echo "version: \"2\""                                        > $(DOCKERYAML)
	@echo "services:"                                            >> $(DOCKERYAML)
	@echo "   build:"                                            >> $(DOCKERYAML)
	@echo "      container_name: $(DOCKERNAME)"                  >> $(DOCKERYAML)
	@echo "      hostname: bct_build"                            >> $(DOCKERYAML)
	@echo "      image: ubuntu:22.04"                            >> $(DOCKERYAML)
	@echo "      tty: true"                                      >> $(DOCKERYAML)
	@echo "      restart: always"                                >> $(DOCKERYAML)
	@echo "      privileged: true"                               >> $(DOCKERYAML)
	@echo "      environment:"                                   >> $(DOCKERYAML)
	@echo "         - DEBIAN_FRONTEND=noninteractive"            >> $(DOCKERYAML)
	@echo "         - USER=$(USER)"                              >> $(DOCKERYAML)
	@echo "      volumes:"                                       >> $(DOCKERYAML)
	@echo "         - /dev:/dev"                                 >> $(DOCKERYAML)
	@echo "         - /var/run/docker.sock:/var/run/docker.sock" >> $(DOCKERYAML)
	@echo "         - $(WDIR):$(WDIR)"                           >> $(DOCKERYAML)
#-----------------------------------------------------------------------------
docker_installapps:
	@#--------------------------------------------------------------------
	@echo
	@echo "[INFO] $(DOCKERNAME) apt update"
	@echo
	@if [ `dpkg -l|grep docker-compose|grep "ii"|wc -l` -eq "0" ] ; then \
		sudo apt update -y ; sudo apt install -y docker-compose ; \
	fi
	@sudo docker exec -t -w $(WDIR) $(DOCKERNAME) apt update
	@#sudo docker exec -t -w $(WDIR) $(DOCKERNAME) apt upgrade -y
	@sudo docker exec -t -w $(WDIR) $(DOCKERNAME) apt install -y $(DEBS)
	@echo
	@echo "[INFO] $(DOCKERNAME) apt update done"
	@echo
	@#--------------------------------------------------------------------
	@echo "docker=\"\\[\\[\\e[1;32;41m\\]DOCKER\\[\\[\\e[0m\\]\""                                                  > $(WDIR)/.tmpps1
	@echo "PS1=\"[\$$docker \\[\\[\\e[1;31m\\]\\u@\\h \\[\\[\\e[0m\\]] \\[\\[\\e[1;33m\\]\\w\\[\\[\\e[0m\\] # \"" >> $(WDIR)/.tmpps1
	@echo "cat $(WDIR)/.tmpps1 >> /root/.bashrc"                      > $(WDIR)/.tmpsh
	@echo "sed -i \"s/ -asis/-asis/\" /etc/joe/joerc"                >> $(WDIR)/.tmpsh
	@echo "sed -i \"s/ -nobackups/-nobackups/\" /etc/joe/joerc"      >> $(WDIR)/.tmpsh
	@echo "sed -i \"s/ -nodeadjoe/-nodeadjoe/\" /etc/joe/joerc"      >> $(WDIR)/.tmpsh
	@echo "sed -i '/root:x:/d' /etc/passwd"                          >> $(WDIR)/.tmpsh
	@echo "echo \"root:x:0:0:root:$(WDIR):/bin/bash\" >>/etc/passwd" >> $(WDIR)/.tmpsh
	@echo "cp -f /root/.bashrc $(WDIR)"                              >> $(WDIR)/.tmpsh
	@#--------------------------------------------------------------------
	@sudo docker exec -t -w $(WDIR) $(DOCKERNAME) /bin/bash $(WDIR)/.tmpsh
	@#--------------------------------------------------------------------
	@rm -f $(WDIR)/.tmpps1 $(WDIR)/.tmpsh
	@#--------------------------------------------------------------------	
#-----------------------------------------------------------------------------
docker: dockercomposeyam
	@#--------------------------------------------------------------------
	@if [ `sudo docker ps -a 2>/dev/null|grep "$(DOCKERNAME)$$"|wc -l` -eq "0" ] ; then \
		echo "[WARN] $(DOCKERNAME) not found " ; \
		cd $(WDIR); sudo docker-compose up -d > /dev/null 2>&1 ; \
	else \
		echo "[INFO] docker $(DOCKERNAME) found" ; \
	fi
	@#--------------------------------------------------------------------
	@if [ `docker ps 2>/dev/null|grep " $(DOCKERNAME)$$"|wc -l` -eq "0" ] ; then \
		echo "[INFO] docker $(DOCKERNAME) startup" ; \
		sudo docker start $(DOCKERNAME) >/dev/null 2>&1; \
	fi
	@#--------------------------------------------------------------------
	@cd $(WDIR); make docker_installapps
	@#--------------------------------------------------------------------
	@echo
	@echo "[INFO] docker $(DOCKERNAME) is running"
	@echo "[INFO] docker $(DOCKERNAME) enter"
	@echo
	@#--------------------------------------------------------------------
	@sudo docker exec -it -w $(WDIR) $(DOCKERNAME) /bin/bash
	@#--------------------------------------------------------------------
	@rm -f $(WDIR)/.bash_history $(WDIR)/.bashrc
	@echo
	@echo "[INFO] docker $(DOCKERNAME) exit"
	@echo 
	@echo " type \" docker exec -it -w $(WDIR) $(DOCKERNAME) /bin/bash \" enter docker again"
	@echo " or \" make docker \" "
	@echo
	@#--------------------------------------------------------------------
#-----------------------------------------------------------------------------
clean:
	@if [ `sudo docker ps -a 2>/dev/null|grep "$(DOCKERNAME)$$"|wc -l` -ne "0" ] ; then \
		echo "[INFO] docker $(DOCKERNAME) stop" ; \
		sudo docker-compose stop >/dev/null 2>&1; \
	fi
#-----------------------------------------------------------------------------
distclean:
	@if [ `sudo docker ps -a 2>/dev/null|grep "$(DOCKERNAME)$$"|wc -l` -ne "0" ] ; then \
		echo "[INFO] docker $(DOCKERNAME) remove" ; \
		sudo docker-compose down > /dev/null 2>&1 ; \
	fi
	@rm -f $(DOCKERYAML);
#-----------------------------------------------------------------------------
endif
#=============================================================================

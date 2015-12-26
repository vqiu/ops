#!/bin/bash
#FileName: git_install.sh
#Description: Script for git
#Author: shuhui

# Define Variables
GLOBAL_NAME="admin"
GLOBAL_EMAIL="admin@vqiu.cn"

# gitosis repository address
GITOSIS_REPO="git://github.com/res0nat0r/gitosis.git"

# Define IP Address
IP="127.0.0.1"

function git_install {

	# Install git 
	git > /dev/null 2>&1
	if [[ $? -eq 0 ]]; then
		echo "git is already installed"
	else
		yum -y install git
	fi

	# Set Global Info.
	git config --global user.name ${GLOBAL_NAME}   
	git config --global user.email ${GLOBAL_EMAIL}

	# Generate the Keys
	if [[ ! -e ~/.ssh/id_rsa ]]; then
		ssh-keygen -t rsa -b 2048 -P "" -f ~/.ssh/id_rsa -C ${GLOBAL_EMAIL}
	fi
}

function add_user {
    id git >/dev/null 2>&1
    if [[ $? -eq 1 ]]; then
        useradd -c "git user" git
    fi 
}

function gitosis {

	cd /usr/local/src

	# Install Dependent Package
	yum -y install python python-setuptools

	# Clone gitosis repositories
	git clone ${GITOSIS_REPO}
	cd gitosis/

	# Install gitosis
	python setup.py install

	# Import Public key
	sudo -H -u git gitosis-init < ~/.ssh/id_rsa.pub

	# Set privileges[Allow update]
	chmod 755 /home/git/repositories/gitosis-admin.git/hooks/post-update
}

function client {
	
	cd ~
	# Clone the Gitosis-admin Repositories
	git clone git@${IP}:gitosis-admin.git
}

git_install
add_user
gitosis
client

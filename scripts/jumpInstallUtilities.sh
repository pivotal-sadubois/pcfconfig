#!/bin/bash

export LC_ALL=en_US.UTF-8

echo "Install Software on Jumphost"
echo "- Update GIT repo https://github.com/pivotal-sadubois/pcfconfig.git"
(cd /home/ubuntu/pcfconfig; git fetch)

echo "- Install AWS CLI"
if [ ! -x /usr/local/bin/aws ]; then 
  sudo apt install python-pip -y
  sudo apt install python3-pip -y
  pip install --upgrade pip
  sudo pip3 install awscli --upgrade 
fi

echo "- Install OM"
if [ ! -x /usr/bin/om ]; then 
  sudo wget -q -O - https://raw.githubusercontent.com/starkandwayne/homebrew-cf/master/public.key | sudo  apt-key add -
  sudo echo "deb http://apt.starkandwayne.com stable main" | sudo  tee /etc/apt/sources.list.d/starkandwayne.list
  sudo apt-get update
  sudo apt-get install om -y
fi

echo "- Install JQ"
if [ ! -x /usr/bin/jq ]; then 
  sudo apt-get install jq -y
fi

echo "- Install Terraform"
if [ ! -x /usr/bin/terraform ]; then 
  sudo apt-get install terraform -y
fi

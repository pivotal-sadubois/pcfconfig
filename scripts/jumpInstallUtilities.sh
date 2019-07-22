#!/bin/bash

export LC_ALL=en_US.UTF-8

echo "Install Software on Jumphost"
echo "- Update GIT repo https://github.com/pivotal-sadubois/pcfconfig.git"
(cd /home/ubuntu/pcfconfig; git fetch)

if [ ! -x /usr/local/bin/aws ]; then 
  echo "- Install AWS CLI"
  sudo apt install python-pip -y
  sudo apt install python3-pip -y
  pip install --upgrade pip
  sudo pip3 install awscli --upgrade 
fi

if [ ! -x /usr/bin/om ]; then 
  echo "- Install OM"
  sudo wget -q -O - https://raw.githubusercontent.com/starkandwayne/homebrew-cf/master/public.key | sudo  apt-key add -
  sudo echo "deb http://apt.starkandwayne.com stable main" | sudo  tee /etc/apt/sources.list.d/starkandwayne.list
  sudo apt-get update
  sudo apt-get install om -y
fi

if [ ! -x /usr/bin/jq ]; then 
  echo "- Install JQ"
  sudo apt-get install jq -y
fi

if [ ! -x /usr/bin/terraform ]; then 
  echo "- Install Terraform"
  wget https://releases.hashicorp.com/terraform/0.11.14/terraform_0.11.14_linux_amd64.zip
  unzip terraform_0.11.14_linux_amd64.zip
  sudo mv terraform /usr/local/bin/
  which terraform
  #sudo apt-get install terraform -y
fi

if [ ! -x /usr/bin/zipinfo ]; then 
  echo "- Install ZIP"
  sudo apt-get install zip -y
fi

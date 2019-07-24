#!/bin/bash

export PIVNET_TOKEN=$1
export LC_ALL=en_US.UTF-8
sudo mkdir -p /usr/local /usr/local/bin

echo "Install Software on Jumphost"
echo "- Pivnet Token: $PIVNET_TOKEN"
echo "- Update GIT repo https://github.com/pivotal-sadubois/pcfconfig.git"
(cd /home/ubuntu/pcfconfig; git fetch)

if [ ! -x /usr/local/bin/aws ]; then 
  echo "- Install AWS CLI"
  #sudo apt install python-pip -y
  #sudo apt install python3-pip -y
  #pip install --upgrade pip
  #sudo pip3 install awscli --upgrade 
  sudo apt install awscli -y
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

if [ ! -x /usr/bin/zipinfo ]; then
  echo "- Install ZIP"
  sudo apt-get install zip -y
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
  wget -O pivnet github.com/pivotal-cf/pivnet-cli/releases/download/v0.0.55/pivnet-linux-amd64-0.0.55 && chmod a+x pivnet && sudo mv pivnet /usr/local/bin
fi

if [ ! -x /usr/bin/pks ]; then 
  pivnet login --api-token=$PIVNET_TOKEN
  PRODUCT_VERSION=$(pivnet releases -p pivotal-container-service --format json | jq -r '.[].version' | head -1)
  PRODUCT_ID=`pivnet product-files -p pivotal-container-service -r $PRODUCT_VERSION --format json | jq -r '.[] | select(.aws_object_key | contains("product-files/pivotal-container-service/pks-linux-amd64")).id'`
  pivnet download-product-files -p pivotal-container-service -r $PRODUCT_VERSION -i $PRODUCT_ID
  FILE_NAME=$(pivnet product-files -p pivotal-container-service -r $PRODUCT_VERSION --format json | jq -r '.[] | select(.aws_object_key | contains("product-files/pivotal-container-service/pks-linux-amd64")).aws_object_key' | awk -F'/' '{ print $NF }')
  chmod a+x $FILE_NAME
  sudo mv $FILE_NAME /usr/local/pks
fi



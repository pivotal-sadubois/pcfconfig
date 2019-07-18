#!/bin/bash

export LC_ALL=en_US.UTF-8

echo "Install Software on Jumphost"
echo "- Update GIT repo https://github.com/pivotal-sadubois/pcfconfig.git"
(cd /home/ubuntu/pcfconfig; git fetch)
echo "- Install bsdutils"
sudo apt-get install bsdutils -y
sudo apt install python-pip -y
sudo apt install python3-pip -y
pip install --upgrade pip
sudo pip3 install awscli --upgrade 
sudo wget -q -O - https://raw.githubusercontent.com/starkandwayne/homebrew-cf/master/public.key | sudo  apt-key add -
sudo echo "deb http://apt.starkandwayne.com stable main" | sudo  tee /etc/apt/sources.list.d/starkandwayne.list
sudo apt-get update
sudo apt-get install om -y

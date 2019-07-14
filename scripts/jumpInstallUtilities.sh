#!/bin/bash

echo "Install Software on Jumphost"
echo "- Update GIT repo https://github.com/pivotal-sadubois/pcfconfig.git"
(cd /home/ubuntu/pcfconfig; git fetch)
echo "- Install bsdutils"
sudo apt-get install script

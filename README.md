# PCF Configuration Utility
The PCF Configuration Utility pcfconfig.sh is to configure the Pivotal OpsManager
and its software tiles over its API interface.  

* Create the initial authentification credentials
* Set the OpsManager configuration
* Configure Networks for PKS and PCF
* Product Upload from PivNet
* Update Stemcells
* Configuring the PKS and PCF tiles

Prerequisites:
* om - https://github.com/pivotal-cf/om
* jq - https://stedolan.github.io/jq/download/
* terraform - https://www.terraform.io/downloads.html

PCF Config Installation:
```
mkdir ~/workspace && cd ~/workspace
git clone https://github.com/pivotal-sadubois/pcfconfig.git
export PATH=~/workspace/pcfconfig:$PATH
```

Runing PCF Config
Change into your Terraform directory for PKS/PAS and execute pcfconfig 

```
$ cd ~/workspace/pivotal-cf-terraforming-azure-370b741/terraforming-pks
$ pcfconfig
USAGE: pcfconfig <mode> [options]
              MODE:    opsmen       - Configure OpsManager
                       pas          - Configure Pivotal Application Service (PAS)
                       pks          - Configure Pivotal Container Service (PKS)
              OPTIONS: -u <admin>   - OpsManager Amdin User
                       -p <admin>   - OpsManager Amdin Password
                       -dp <phrase> - OpsManager Decryption Prhase
                       --debug      - Debugging
                       --noapply    - Do not Apply changes on OpsManager

$ pcfconfig opsman --noapply -u admin -p pivotal -dp pivotal
```




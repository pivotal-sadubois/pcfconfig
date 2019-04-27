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

```
mkdir ~/workspace && cd ~/workspace
git clone https://github.com/pivotal-sadubois/pcfconfig.git
```

* Then we should update the versions used in our app

```
update pcf_versions
set script_version = 'v1.0.12'
where script_version = 'v1.0.11'
```
AND
```
update pks_versions
set script_version = 'v1.0.12'
where script_version = 'v1.0.11'
```

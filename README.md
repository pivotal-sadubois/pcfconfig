# PCF Configuration Utility
The PCF Configuration Utility is to automaticly deploy PKS/PAS on the Microsoft Azure, Amazon Web Services (AWS)
and the Goodle Gloud Platform (GCP) unattended. 

* Creates a dedicated jump server on every environment
* Configure Terraforms to deploy network, storage, FW, LoadBalancers 
* Create the initial authentification credentials for the Ops Manager
* Set the OpsManager configuration via API
* Configure Networks for PKS and PCF
* Product Upload from PivNet
* Update Stemcells
* Configuring the PKS and PCF tiles

Prerequisites:
* DNS hosted domain on AWS Route53: https://console.aws.amazon.com/route53
* AWS CLI Installed and configured: https://docs.aws.amazon.com/cli/latest/userguide/install-linux-al2017.html

PCF Config Installation:
```
mkdir ~/workspace && cd ~/workspace
git clone https://github.com/pivotal-sadubois/pcfconfig.git
```

Runing PCF Config
```
$ ./deployPCF

PCF Deployment Utility (deployPCF)
by Sacha Dubois, Pivotal Inc,
-----------------------------------------------------------------------------------------------------------
CONFIURATION              CLOUD DEPLOYMENT MAINTAINER DESCRIPTION
-----------------------------------------------------------------------------------------------------------
aws-pas-2.6.6.cfg         AWS   PAS 2.6.4  sadubois   PAS on AWS Cloud
aws-pks-1.5.cfg           AWS   PKS 1.5    sadubois   PKS on AWS
azure-pas-2.6.6.cfg       Azure PKS 1.5    sadubois   PAS on Azure Cloud with Availability Sets
azure-pks-1.4.1.cfg       Azure PKS 1.4.1  sadubois   PKS on Azure Cloud with Availability Zones
azure-pks-1.5.cfg         Azure PKS 1.5    sadubois   PKS on Azure Cloud with Availability Zones
gcp-pks-1.5.cfg           GCP   PKS 1.5    sadubois   PKS on GCP
-----------------------------------------------------------------------------------------------------------
USAGE: deployPCF <deployment.cfg>

```
Choose a deployment config that fits your need and start deployPCF again.

```
$ ./deployPCF gcp-pks-1.5.cfg

PCF Deployment Utility (deployPCF)
by Sacha Dubois, Pivotal Inc,
-----------------------------------------------------------------------------------------------------------
Deployment Settings
 - Cloud Provider ........................................: GCP
 - Environment Name ......................................: gcppks
 - Deployment Description ................................: PKS on GCP
 - Debug Information .....................................: false
Operation Manager Configuration
 - OpsManager Version ....................................: 2.5.4
 - OM Configuration File .................................: templates/opsman_gcp_pks.yml
 - Administrator User ....................................: admin
 - Administrator Password ................................: pivotal
----------------------------------------------------------------------------------------------------------------
checking for gcloud CLI utility ..........................: installed - 260.0.0
checking for AWS CLI utility (needed for AWS Route53) ....: installed - 1.16.230
----------------------------------------------------------------------------------------------------------------
GCP Access Credentials
 - GCP Service Account ...................................: /Users/sadubois/GCP/pcfconfig-pa-sadubois-3-46388c43c13d.json
 - GCP Project ...........................................: pa-sadubois-3
 - GCP Region ............................................: europe-west1

  MISSING ENVIRONMENT-VARIABES    DESCRIPTION        
  --------------------------------------------------------------------------------------------------------------
  To allow TLS encrypted httpd traffic a Certificate and key needs to be created for your DNS Domain. Free
  certificates can be optained through https://letsencrypt.org.

  GCP_PKS_TLS_CERTIFICATE       (optional)  TLS Certificate (type PEM Certificate)
  GCP_PKS_TLS_FULLCHAIN         (optional)  TLS Fullchain (type PEM Certificate)
  GCP_PKS_TLS_PRIVATE_KEY       (optional)  TLS Private Key
  GCP_PKS_TLS_ROOT_CA           (automatic) TLS Root CA
                                  
                                  gcppks.pcfsdu.com
                                    |      |_________ represented by the PCF_ENVIRONMENT_NAME variable
                                    |________________ represented by the AWS_HOSTED_DNS_DOMAIN variable

                                  The certificate Should include the following domains:
                                  - PKS Services (API, OpsMan, Harbor) .: *.gcppks.pcfsdu.com
                                  - PKS Cluster and Applications .......: *.apps.cl1.gcppks.pcfsdu.com
                                                                          *.apps.cl2.gcppks.pcfsdu.com
                                                                          *.apps.cl3.gcppks.pcfsdu.com

Supporting services access (Pivotal Network, AWS Route53)
 - Pivotal Network Token .................................: f8ea72c2e1ce4cc8b9254ee6d0f37c75-r
 - AWS Route53 Hosted DNS Domain .........................: pcfsdu.com
 - AWS Route53 ZoneID ....................................: Z1X9T7571BMHB5
  --------------------------------------------------------------------------------------------------------------
  IMPORTANT: Please set the missing environment variables either in your shell or in the pcfconfig
             configuration file ~/.pcfconfig and set all variables with the 'export' notation
             ie. => export AZURE_PKS_TLS_CERTIFICATE=/home/demouser/certs/cert.pem
  --------------------------------------------------------------------------------------------------------------
Creating GCP Jump-Server .................................: jump-gcppks.pcfsdu.com
 - Verify VM (jump-gcppks.pcfsdu.com) ....................: jump-gcppks.pcfsdu.com
 - Verify SSH Access .....................................: success
 - Update GIT repo .......................................: https://github.com/pivotal-sadubois/pcfconfig.git

# --- JUMP HOST ACCESS ---
ssh -q -o StrictHostKeyChecking=no -o RequestTTY=yes -o ServerAliveInterval=30 sadubois@jump-gcppks.europe-west1-b.pa-sadubois-3

```
The script requires you to set some environment variable such as Cloud Access credentials in the ~/.pcfconfig file before it starts. This script is running arround 90min unattended. If the terminal session is lost during the installation, just restart the
script again and it will continue where it has stopped

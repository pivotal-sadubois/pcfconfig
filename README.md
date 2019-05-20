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
* route53 - DNS hosted domain: https://console.aws.amazon.com/route53

PCF Config Installation:
```
mkdir ~/workspace && cd ~/workspace
git clone https://github.com/pivotal-sadubois/pcfconfig.git
export PATH=~/workspace/pcfconfig:$PATH
```

Runing PCF Config
Change into your Terraform directory for PKS/PAS and execute pcfconfig to see the options
```
USAGE: pcfconfig [options]
             Configuration Settings
                       --admin-user <login>             - OpsManager Admin User
                       --admin-pass <password>          - OpsManager Admin Password
                       --decryption-key <phrase>        - OpsManager Decryption Prhase
                       --pivnet-token <token>           - Pivnet API Token
                       --workdir <directory>            - Working Directory (default: ~/workspace)
                       --env-name <name>                - Environment Name
                       --dns-domain <vars>              - DNS Domain Name
                       --aws-route53 <token>            - AWS Route53 Token

             Product Settings>
                       --pks-version <version>          - PKS Version
                       --pks-user <version>             - PKS Admin User
                       --pks-pass <version>             - PKS Admin Password
                       --pas-version <version>          - PAS Version
                       --harbor-version <version>       - PAS Version

             Google Cloud Platform (GCP)
                       --gcp-service-account <file>     - GCP Access Key
                       --gcp-region <val>               - GCP Region  (gcloud projects list)
                       --gcp-project-name <val>         - GCP Project (gcloud compute zones list)

             Microsoft Azure Cloud (Azure)
                       --azure-subscription_id <val>    - Azure Subscription Id
                       --azure-tenant_id <val>          - Azure Tenant Id
                       --azure-client_id <val>          - Azure Client/Application Id
                       --azure-client_secret            - Azure Client Secret
                       --azure-location <val>           - Azure Location

             Amazon Web Services (AWS)
                       --aws-access_key <val>           - AWS Access Key
                       --aws-secret_key <val>           - AWS Secret Key
                       --aws-region <val>               - AWS Region
```
To perform a fully unattended installation. You need to create a script containing the required settings for 
your environment. Currently only PKS is supported for AWS and GCP Cloud. 


```
$ vi install-gcp-pks-1.4.sh
#!/bin/bash
export PATH=~/workspace/pcfconfig:$PATH
PIVNET_TOKEN=""
LOCATION="europe-west4"
DNS_DOMAIN="pcfsdu.com"
AWS_ROUTE53_TOKEN=""
OPSMAN_USER="admin"
OPSMAN_PASS=""
OPSMAN_DECRYPTION_KEY="pivotal"
PKS_VERISON="1.4.0"
ENV_NAME="gcppks"
SERVICE_ACCOUNT=~/GCP/pcfconfig-key.json

pcfconfig    --pivnet-token $PIVNET_TOKEN --pks-version "${PKS_VERISON}" \
             --directory-prefix cf-terraform --dns-domain "${DNS_DOMAIN}" \
             --admin-user "${OPSMAN_USER}" --admin-pass "${OPSMAN_PASS}" \
             --decryption-key "${OPSMAN_DECRYPTION_KEY}" --gcp-project-name pa-sadubois \
             --env-name "${ENV_NAME}" --aws-route53 "${AWS_ROUTE53_TOKEN}" \
             --azure-client_secret "${CLIENT_SECRET}" --gcp-region "${LOCATION}" \
             --gcp-service-account $SERVICE_ACCOUNT --env-name "${ENV_NAME}"
```

When you start the script you would see an output similiar to the following: 
```
PCF Configuration Utility (pcfconfig)
by Sacha Dubois, Pivotal Inc,
-----------------------------------------------------------------------------------------------------------
checking for  CLI utility ................................: installed - 246.0.0

PCF Configuration Utility (pcfconfig-terraform)
by Sacha Dubois, Pivotal Inc,
-----------------------------------------------------------------------------------------------------------
checking for the om utility ..............................: Installed - 0.56.0
checking for the jq utility ..............................: Installed - jq-1.6
checking for the terraform  ..............................: Installed - v0.11.13
checking for the openssl utility .........................: Installed - LibreSSL 2.6.5
checking for  CLI utility ................................: installed - 246.0.0
-----------------------------------------------------------------------------------------------------------
             PCF Version  Terraform Templates               Released    End od Support
             ----------------------------------------------------------------------------------------------
PCF 2.5      PCF-2.5.3    GCP Terraform Templates 0.74.0    2019-05-08  2019-12-31
             PCF-2.5.2    GCP Terraform Templates 0.74.0    2019-04-18  2019-12-31
             PCF-2.5.1    GCP Terraform Templates 0.74.0    2019-04-10  2019-12-31
-----------------------------------------------------------------------------------------------------------
PCF 2.4      PCF-2.4.7    GCP Terraform Templates 0.74.0    2019-05-08  2019-09-30
             PCF-2.4.6    GCP Terraform Templates 0.74.0    2019-04-18  2019-09-30
             PCF-2.4.5    GCP Terraform Templates 0.74.0    2019-04-10  2019-09-30
-----------------------------------------------------------------------------------------------------------
Download Terraform Configuration
 - PCF Version ...........................................: 2.5.3
 - Terraform Template Version ............................: 0.74.0
 - Deployment Environment ................................: gcp
 - Terraform Directory Prefix ............................: cf-terraform
 - Terraform Instalation Directory .......................: ~/workspace/cf-terraform-gcp
-----------------------------------------------------------------------------------------------------------
             OpsManager (Version/Build)  Ops-Manager Install Image          Released    End od Support
             ----------------------------------------------------------------------------------------------
PCF 2.5      2.5.4   2.5.4-build.189     ops-manager-us/pcf-gcp-2.5.4-build.189.tar.gz 2019-05-17  2019-12-30
             2.5.3   2.5.3-build.185     ops-manager-us/pcf-gcp-2.5.3-build.185.tar.gz 2019-05-14  2019-12-30
             2.5.2   2.5.2-build.172     ops-manager-us/pcf-gcp-2.5.2-build.172.tar.gz 2019-04-19  2019-12-30
-----------------------------------------------------------------------------------------------------------
PCF 2.4      2.4.11  2.4-build.202       ops-manager-us/pcf-gcp-2.4-build.202.tar.gz 2019-05-17  2019-09-30
             2.4.10  2.4-build.192       ops-manager-us/pcf-gcp-2.4-build.192.tar.gz 2019-05-08  2019-09-30
             2.4.9   2.4-build.180       ops-manager-us/pcf-gcp-2.4-build.180.tar.gz 2019-04-19  2019-09-30
-----------------------------------------------------------------------------------------------------------
PCF 2.3      2.3.18  2.3-build.313       ops-manager-us/pcf-gcp-2.3-build.313.tar.gz 2019-05-17  2019-06-30
             2.3.17  2.3-build.305       ops-manager-us/pcf-gcp-2.3-build.305.tar.gz 2019-05-08  2019-06-30
             2.3.16  2.3-build.300       ops-manager-us/pcf-gcp-2.3-build.300.tar.gz 2019-04-30  2019-06-30
-----------------------------------------------------------------------------------------------------------
OpsManager Information (terraform.tfvars)
 - Terraform Variable File (Source) ......................: /tmp/terraform_gcp.tfvars
 - Terraform Variable File (Local) .......................: terraform.tfvars
 - OpsManager Image ......................................: ops-manager-us/pcf-gcp-2.5.4-build.189.tar.gz
 - OpsManager Version ....................................: 2.5.4
 - PCF Cloud .............................................: gcp
 - PCF Region ............................................: europe-west4

WARNING: pcfconfig-terraform is going to overwrite the /Users/sadubois/workspace/cf-terraform-gcp directory
         Be sure you have executed 'terraform destroy' first
  => Do you want to proceede ? <y/n>: y
 - Deleting existing instalation Directory ...............: ~/workspace/cf-terraform-gcp-2.5.3
 - Placing Terraform Variable file .......................: /Users/sadubois/workspace/cf-terraform-gcp/terraforming-pks/terraform.tfvars

-----------------------------------------------------------------------------------------------------------
Terraform configuration completed. Change to the terraform directory:
=> /Users/sadubois/workspace/cf-terraform-gcp/terraforming-pks for PKS and proceed with pcfconfig-opsman
--------------------------------------- TERRAFORM DEPLOYMENT ----------------------------------------------
pks_subnet_cidr = 10.0.10.0/24
pks_subnet_cidrs = [
    10.0.10.0/24
]
pks_subnet_gateway = 10.0.10.1
pks_subnet_name = gcppks-pks-subnet
pks_worker_node_service_account_key = <sensitive>
project = pa-sadubois
region = europe-west4
service_account_email = gcppks-opsman@pa-sadubois.iam.gserviceaccount.com
services_subnet_cidr = 10.0.11.0/24
services_subnet_cidrs = [
    10.0.11.0/24
]
services_subnet_gateway = 10.0.11.1
services_subnet_name = gcppks-pks-services-subnet
sql_db_ip = 
ssl_cert = <sensitive>
ssl_private_key = <sensitive>
vm_tag = gcppks-vms
-----------------------------------------------------------------------------------------------------------

PCF Configuration Utility (pcfconfig-opsman)
by Sacha Dubois, Pivotal Inc,
-----------------------------------------------------------------------------------------------------------
checking for the om utility ..............................: Installed - 0.56.0
checking for the jq utility ..............................: Installed - jq-1.6
checking for the terraform  ..............................: Installed - v0.11.13
checking for the openssl utility .........................: Installed - LibreSSL 2.6.5
checking terraform product selection .....................: Pivotal Container Service (PKS)
checking terraform cloud provider ........................: Google Gloud Platform (GCP)
checking for GCP CLI utility .............................: installed - 246.0.0
Verify GCP configuration:
 - GCP ServiceAccount ....................................: pcfconfig@pa-sadubois.iam.gserviceaccount.com
 - GCP ServiceAccount ProjectID ..........................: pa-sadubois
 - GCP Region ............................................: europe-west4
 - GCP Availability Zone .................................: europe-west4-a, europe-west4-b, europe-west4-c
 - DNS Domain Suffix .....................................: pcfsdu.com
 - DNS Domain Prefix .....................................: gcppks
 - DNS SubDomain .........................................: gcppks.pcfsdu.com
 - OPS Manager AMI .......................................: ops-manager-us/pcf-gcp-2.5.4-build.189.tar.gz - 2.5.4
Verify GCP Ops Manager instance
 - Ops Manager VM Name ...................................: gcppks-ops-manager
 - Ops Manager Instance ..................................: RUNNING
 - DNS Servers ...........................................: ns-cloud-d1.googledomains.com. ns-cloud-d2.googledomains.com. ns-cloud-d3.googledomains.com. ns-cloud-d4.googledomains.com.
 - Ops Manager DNS Name ..................................: pcf.gcppks.pcfsdu.com
Updating AWS Route53 DNS records:
 - Validating AWS Route53 ZoneID .........................: Z1X9T7571BMHB5
 - Validating AWS Route53 Zone: (pcfsdu.com) .............: zone managed by route53
 - Define DNS Record for (gcppks.pcfsdu.com) .............: 
       gcppks.pcfsdu.com    NS     ns-cloud-d1.googledomains.com.
                                   ns-cloud-d2.googledomains.com.
                                   ns-cloud-d3.googledomains.com.
                                   ns-cloud-d4.googledomains.com.
 - Updating AWS Route53 Record for (gcppks.pcfsdu.com) ...: succeeded
Waiting for DNS records to be pushed ............................................................ [060/060]

Validating OPS Manager DNS records (pcf.gcppks.pcfsdu.com)
   => Verify DNS lookup Google (8.8.8.8) .................: successful
   => Verify DNS lookup (ns-cloud-d1.googledomains.com.) .: successful
   => Verify DNS lookup (ns-cloud-d2.googledomains.com.) .: successful
   => Verify DNS lookup (ns-cloud-d3.googledomains.com.) .: successful
   => Verify DNS lookup (ns-cloud-d4.googledomains.com.) .: successful
   => Verify DNS lookup localhost (10.70.0.10) ...........: successful
 - Ops Manager Public IP .................................: 34.90.220.211
 - Ops Manager Private IP ................................: 10.0.0.2
OpsManager Configuration Definitions (opsman_gcp.yml)
 - OpsManager Version:   .................................: 2.5.4
 - OpsManager Build:   ...................................: 2.5.4-build.189
 - Template File:   ......................................: /Users/sadubois/workspace/pcfconfig/templates/opsman_gcp.yml
 - Template Status:   ....................................: stable
 - Template Maintained by:   .............................: sadubois
 - Template Tested:   ....................................: 2019-05-19
 - Template Description:   ...............................: no issues 
Configure OpsManager Authentification
 - OpsManager URL ........................................: http://pcf.gcppks.pcfsdu.com
 - OpsManager Admin User .................................: admin
 - OpsManager Admin Password .............................: pivotal
 - OpsManager Decryption Passphrase ......................: pivotal
-----------------------------------------------------------------------------------------------------------
configuring internal userstore...
waiting for configuration to complete...
configuration complete
-----------------------------------------------------------------------------------------------------------
Configure OpsManager Parameters
 - OpsManager URL ........................................: http://pcf.gcppks.pcfsdu.com
 - OpsManager Template ...................................: /Users/sadubois/workspace/pcfconfig/templates/opsman_gcp.yml
 - OpsManager Variable File ..............................: ./opsman_vars.yml
--------------------------------- CONFIGURING OPSMANAGER STAGE-1 ------------------------------------------
started configuring director options for bosh tile
finished configuring director options for bosh tile
--------------------------------- CONFIGURING OPSMANAGER STAGE-2 ------------------------------------------
started configuring director options for bosh tile
finished configuring director options for bosh tile
started configuring availability zone options for bosh tile
successfully fetched AZs, continuing
finished configuring availability zone options for bosh tile
started configuring network options for bosh tile
finished configuring network options for bosh tile
started configuring network assignment options for bosh tile
finished configuring network assignment options for bosh tile
started configuring resource options for bosh tile
applying resource configuration for the following jobs:
	compilation
	director
finished configuring resource options for bosh tile
started configuring vm extensions
applying vmextensions configuration for the following:
finished configuring vm extensions
-----------------------------------------------------------------------------------------------------------
Applying Changes to OpsManager

Configuration of the OpsManager completed. You may proceede with pcfconfig-pks / pcfconfig-pas

PCF Configuration Utility (pcfconfig-pks)
by Sacha Dubois, Pivotal Inc,
-----------------------------------------------------------------------------------------------------------
checking for the om utility ..............................: Installed - 0.56.0
checking for the jq utility ..............................: Installed - jq-1.6
checking for the terraform  ..............................: Installed - v0.11.13
checking for the openssl utility .........................: Installed - LibreSSL 2.6.5
checking terraform product selection .....................: Pivotal Container Service (PKS)
checking terraform cloud provider ........................: Google Gloud Platform (GCP)
checking for GCP CLI utility .............................: installed - 246.0.0
Verify GCP configuration:
 - GCP ServiceAccount ....................................: pcfconfig@pa-sadubois.iam.gserviceaccount.com
 - GCP ServiceAccount ProjectID ..........................: pa-sadubois
 - GCP Region ............................................: europe-west4
 - GCP Availability Zone .................................: europe-west4-a, europe-west4-b, europe-west4-c
 - DNS Domain Suffix .....................................: pcfsdu.com
 - DNS Domain Prefix .....................................: gcppks
 - DNS SubDomain .........................................: gcppks.pcfsdu.com
 - OPS Manager AMI .......................................: ops-manager-us/pcf-gcp-2.5.4-build.189.tar.gz - 2.5.4
Verify GCP Ops Manager instance
 - Ops Manager VM Name ...................................: gcppks-ops-manager
 - Ops Manager Instance ..................................: RUNNING
 - DNS Servers ...........................................: ns-cloud-d1.googledomains.com. ns-cloud-d2.googledomains.com. ns-cloud-d3.googledomains.com. ns-cloud-d4.googledomains.com.
 - Ops Manager DNS Name ..................................: pcf.gcppks.pcfsdu.com
Validating OPS Manager DNS records (pcf.gcppks.pcfsdu.com)
   => Verify DNS lookup Google (8.8.8.8) .................: successful
   => Verify DNS lookup (ns-cloud-d1.googledomains.com.) .: successful
   => Verify DNS lookup (ns-cloud-d2.googledomains.com.) .: successful
   => Verify DNS lookup (ns-cloud-d3.googledomains.com.) .: successful
   => Verify DNS lookup (ns-cloud-d4.googledomains.com.) .: successful
   => Verify DNS lookup localhost (10.70.0.10) ...........: successful
 - Ops Manager Public IP .................................: 34.90.220.211
 - Ops Manager Private IP ................................: 10.0.0.2
Verify Bosh/0 Instance
 - BOSH Director (Bosh/0) InstanceID .....................: vm-db6f5cf4-6262-414f-4da8-1c8a0d2021e7
 - BOSH Director (Bosh/0) Zone ...........................: europe-west4-a
 - BOSH Director (Bosh/0) Instance State .................: RUNNING
Looking for PKS Product Image (1.4.0)
 - PKS Product Version requested .........................: 1.4.0
 - PIVNET Product SLAG ...................................: pivotal-container-service
 - PIVNET Product GLOB ...................................: pivotal-container-service-1.4.0-build.31.pivotal
 - Verify download and caching options ...................: ops-manager
-----------------------------------------------------------------------------------------------------------
attempting to download the file product-files/pivotal-container-service/pivotal-container-service-1.4.0-build.31.pivotal from source pivnet
```


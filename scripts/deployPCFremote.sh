#!/bin/bash
# ############################################################################################
# File: ........: deployPCFremote.sh
# Language .....: bash
# Author .......: Sacha Dubois, Pivotal
# Description ..: PCF Installation and Configuration Utility
# ############################################################################################

if [ "${1}" == "" ]; then
  echo "$0 <env-file>"; exit 0
fi

envFile=$1

export PCFCONFIG_BASE=$(basename $0)
export PCFPATH=$HOME/pcfconfig

# --- SOURCE FUNCTIONS---
. ${PCFPATH}/functions
. $envFile

if [ "$PCF_TILE_PKS_DEPLOY" == "true" ]; then
  PRODUCT_TILE=pks
  PRODUCT_TILE_NAME=PKS
  PCF_VERSION=$PCF_TILE_PKS_VERSION
  TF_TILE_OPTION="--pks-tfvars"
else
  PRODUCT_TILE=pas
  PRODUCT_TILE_NAME=PAS
  PCF_VERSION=$iPCF_TILE_PAS_VERSION
  TF_TILE_OPTION="--pas-tfvars"
fi

if [ "${PCF_DEPLOYMENT_DEBUG}" == "true" ]; then
  DEBUG=1
else
  DEBUG=0
fi
 
PAS_SRT=1
TF_WORKDIR="$(dirname ~/workspace)/$(basename ~/workspace)"

if [ "$PCF_DEPLOYMENT_DEBUG" == "true" ]; then DEBUG_FLAG="--debug"; else DEBUG_FLAG=""; fi

if [ $DEBUG -gt 0 ]; then 
  echo "PCF_PIVNET_TOKEN:$PCF_PIVNET_TOKEN"
  echo "AWS_HOSTED_ZONE_ID:$AWS_HOSTED_ZONE_ID"
  echo "PCF_OPSMANAGER_ADMIN_USER:$PCF_OPSMANAGER_ADMIN_USER"
  echo "PCF_OPSMANAGER_ADMIN_PASS:$PCF_OPSMANAGER_ADMIN_PASS"
  echo "PCF_OPSMANAGER_DECRYPTION_KEY:$PCF_OPSMANAGER_DECRYPTION_KEY"
  echo "PCF_TILE_PKS_VERSION:$PCF_TILE_PKS_VERSION"
  echo "PCF_TILE_PAS_VERSION:$PCF_TILE_PAS_VERSION"
  echo "AZURE_SUBSCRIPTION_ID:$AZURE_SUBSCRIPTION_ID"
  echo "AZURE_TENANT_ID:$AZURE_TENANT_ID"
  echo "AZURE_CLIENT_ID:$AZURE_CLIENT_ID"
  echo "AZURE_CLIENT_SECRET:$AZURE_CLIENT_SECRET"
  echo "AZURE_REGION:$AZURE_REGION"
  echo "AWS_ACCESS_KEY:$AWS_ACCESS_KEY"
  echo "AWS_SECRET_KEY:$AWS_SECRET_KEY"
  echo "AWS_REGION:$AWS_REGION"
  echo "AWS_HOSTED_DNS_DOMAIN:$AWS_HOSTED_DNS_DOMAIN"
  echo "PCF_DEPLOYMENT_CLOUD:$PCF_DEPLOYMENT_CLOUD"
  echo "PRODUCT_TILE:$PRODUCT_TILE"
fi

echo ""
echo "PCF Configuration Utility ($PCFCONFIG_BASE)"
echo "by Sacha Dubois, Pivotal Inc,"
echo "-----------------------------------------------------------------------------------------------------------"

[ "$PCF_DEPLOYMENT_CLOUD" == "AWS" ] && TF_DEPLOYMENT="aws"
[ "$PCF_DEPLOYMENT_CLOUD" == "Azure" ] && TF_DEPLOYMENT="azure"
[ "$PCF_DEPLOYMENT_CLOUD" == "GCP" ] && TF_DEPLOYMENT="gcp"

checkCloudCLI
checkOpsMantools

##############################################################################################
###################################### SSL VERIFICATION ######################################
##############################################################################################

TLS_CERTIFICATE=$HOME/pcfconfig/certificates/cert.pem
TLS_FULLCHAIN=$HOME/pcfconfig/certificates/fullchain.pem
TLS_PRIVATE_KEY=$HOME/pcfconfig/certificates/privkey.pem
TLS_CHAIN=$HOME/pcfconfig/certificates/chain.pem
TLS_ROOT_CERT=$HOME/pcfconfig/certificates/ca.pem
TLS_ROOT_CA=""

verifyCertificate "$PCF_DEPLOYMENT_CLOUD" PKS "$TLS_CERTIFICATE" "$TLS_FULLCHAIN" \
                  "$TLS_PRIVATE_KEY" "$TLS_CHAIN" "$TLS_ROOT_CA"

##############################################################################################
######################################### PREPERATION ########################################
##############################################################################################

if [ "${PCF_DEPLOYMENT_CLOUD}" == "GCP" ]; then 
  GCP_SERVICE_ACCOUNT=/tmp/${PCF_DEPLOYMENT_ENV_NAME}.terraform.key.json
  gcloud iam service-accounts create ${PCF_DEPLOYMENT_ENV_NAME} --display-name "GCP PAS Manual" > /dev/null 2>&1
  gcloud iam service-accounts keys create "$GCP_SERVICE_ACCOUNT" \
         --iam-account "${PCF_DEPLOYMENT_ENV_NAME}@${GCP_PROJECT}.iam.gserviceaccount.com" > /dev/null 2>&1
  gcloud projects add-iam-policy-binding ${GCP_PROJECT} \
         --member "serviceAccount:${PCF_DEPLOYMENT_ENV_NAME}@${GCP_PROJECT}.iam.gserviceaccount.com" \
         --role "roles/owner" > /dev/null 2>&1
fi

if [ "${PCF_DEPLOYMENT_CLOUD}" == "GCP1" ]; then 
  # --- VERIFY GCP SERVICE ACCOUNTS ---
  if [ ! -f "${GCP_SERVICE_ACCOUNT}" ]; then 
    cnt=$(gcloud iam service-accounts list | grep -c " pcfconfig@" | grep -v "EMAIL")
    if [ $cnt -eq 0 ]; then
      messagePrint "Creating Servivce-Account" "pcfconfig"
  
      gcloud iam service-accounts create pcfconfig --display-name="pcfconfig" 2>/dev/null
      if [ $? -ne 0 ]; then
        echo "ERROR: Creating Service account: pcfconfig failed"; exit 1
      else
        sleep 5
      fi
  
      svc=$(gcloud iam service-accounts list --filter "name:pcfconfig" | grep -v "EMAIL" | awk '{ print $(NF-1) }')
  
      gcloud iam service-accounts add-iam-policy-binding $svc \
        --member="serviceAccount:$svc" --role="roles/owner" > /dev/null 2>&1
      gcloud projects add-iam-policy-binding $GCP_PROJECT \
        --member="serviceAccount:$svc" --role="roles/owner" > /dev/null 2>&1
    fi
  
    # DELETE OLD KEYS
    svc=$(gcloud iam service-accounts list --filter "name:pcfconfig@" | grep -v "EMAIL" | head -1 | awk '{ print $(NF-1) }')
    for n in $(gcloud iam service-accounts keys list --iam-account=$svc | awk '{ print $1 }' | grep -v KEY_ID); do
      gcloud iam service-accounts keys delete --iam-account=$svc $n -q > /dev/null 2>&1
    done
  
    gcloud iam service-accounts keys create $GCP_SERVICE_ACCOUNT --iam-account=${svc} > /dev/null 2>&1
  fi
fi

##############################################################################################
######################################## MAIN PROGRAMM #######################################
##############################################################################################

# --- GENERATE TERRAFORM VARFILE (terraform.tfvars) ---
TF_VARFILE="/tmp/terraform_${TF_DEPLOYMENT}.tfvars"; rm -f $TF_VARFILE; touch $TF_VARFILE

# --- REGION FIX ---
if [ "${PCF_DEPLOYMENT_CLOUD}" == "GCP" ]; then 
  cnt=$(echo "$GCP_REGION" | grep -c "europe")
  if [ $cnt -gt 0 ]; then SEARCH_REG="eu"; fi
  cnt=$(echo "$GCP_REGION" | grep -c "asia")
  if [ $cnt -gt 0 ]; then SEARCH_REG="asia"; fi
  cnt=$(echo "$GCP_REGION" | egrep -c "northamerica|us")
  if [ $cnt -gt 0 ]; then SEARCH_REG="us"; fi
fi

if [ "${PCF_DEPLOYMENT_CLOUD}" == "AWS" ]; then 
  SEARCH_REG="$AWS_REGION"
fi 

if [ "${PCF_DEPLOYMENT_CLOUD}" == "Azure" ]; then 
  cnt=$(echo "$AZURE_REGION" | egrep -c "europe")
  if [ $cnt -gt 0 ]; then SEARCH_REG="west_europe"; fi
  cnt=$(echo "$AZURE_REGION" | egrep -c "_us")
  if [ $cnt -gt 0 ]; then SEARCH_REG="east_us"; fi
  cnt=$(echo "$AZURE_REGION" | egrep -c "_asia")
  if [ $cnt -gt 0 ]; then SEARCH_REG="southeast_asia"; fi
fi

if [ "${PCF_DEPLOYMENT_CLOUD}" == "GCP" ]; then
  list=$(gcloud compute zones list | grep "${GCP_REGION}" | awk '{ print $1 }')
  GCP_AZ1=$(echo $list | awk '{ print $1 }')
  GCP_AZ2=$(echo $list | awk '{ print $2 }')
  GCP_AZ3=$(echo $list | awk '{ print $3 }')

  OPSMAN_IMAGE=$(getOpsManagerAMI $PCF_DEPLOYMENT_CLOUD $PCF_OPSMANAGER_VERSION)

  echo "env_name           = \"${PCF_DEPLOYMENT_ENV_NAME}\""                   >> $TF_VARFILE
  echo "region             = \"${GCP_REGION}\""                                >> $TF_VARFILE
  echo "zones              = [\"${GCP_AZ1}\", \"${GCP_AZ2}\", \"${GCP_AZ3}\"]" >> $TF_VARFILE
  echo "opsman_image_url   = \"${OPSMAN_IMAGE}\""                              >> $TF_VARFILE
  echo "dns_suffix         = \"${AWS_HOSTED_DNS_DOMAIN}\""                     >> $TF_VARFILE
  echo "project            = \"${GCP_PROJECT}\""                               >> $TF_VARFILE
  echo ""                                                                      >> $TF_VARFILE
  echo "ssl_cert = <<SSL_CERT"                                                 >> $TF_VARFILE

  if [ "$TLS_FULLCHAIN" != "" ]; then 
    cat $TLS_FULLCHAIN >> $TF_VARFILE
  fi

  echo "SSL_CERT"                                                              >> $TF_VARFILE
  echo ""                                                                      >> $TF_VARFILE
  echo "ssl_private_key = <<SSL_KEY"                                           >> $TF_VARFILE

  if [ "$TLS_PRIVATE_KEY" != "" ]; then 
    cat $TLS_PRIVATE_KEY >> $TF_VARFILE
  fi

  echo "SSL_KEY"                                                               >> $TF_VARFILE

echo "GCP_SERVICE_ACCOUNT:$GCP_SERVICE_ACCOUNT"
  if [ -f $GCP_SERVICE_ACCOUNT ]; then
    PRJ=$(cat $GCP_SERVICE_ACCOUNT | jq -r '.project_id')
echo "PRJ:$PRJ"
    if [ "${PRJ}" == "$GCP_PROJECT" ]; then 
      echo "service_account_key = <<SERVICE_ACCOUNT_KEY"     >> $TF_VARFILE
      cat /tmp/$PCF_DEPLOYMENT_ENV_NAME.terraform.key.json"  >> $TF_VARFILE
      echo "SERVICE_ACCOUNT_KEY"                             >> $TF_VARFILE
    else
      echo "ERROR: Project-Id ($PRJ) in Service Account ($GCP_SERVICE_ACCOUNT) does not match with"
      echo "       whith the Service Account provided with the option --gcp-service-account $GCP_PROJECT"
      exit 1
    fi
  else
    echo "ERROR: Service Account File ($GCP_SERVICE_ACCOUNT) could not be found"; exit
  fi
fi


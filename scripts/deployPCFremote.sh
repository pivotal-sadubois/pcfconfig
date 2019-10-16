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


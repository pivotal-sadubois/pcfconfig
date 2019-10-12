#!/bin/bash
# ############################################################################################
# File: ........: removePCFenv.sh
# Language .....: bash
# Author .......: Sacha Dubois, Pivotal
# Description ..: Remove PCF Installation 
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
 
DEBUG=0
PAS_SRT=1
TF_WORKDIR="$(dirname ~/workspace)/$(basename ~/workspace)"

echo ""
echo "PCF Configuration Utility ($PCFCONFIG_BASE)"
echo "by Sacha Dubois, Pivotal Inc,"
echo "-----------------------------------------------------------------------------------------------------------"

[ "$PCF_DEPLOYMENT_CLOUD" == "AWS" ] && TF_DEPLOYMENT="aws"
[ "$PCF_DEPLOYMENT_CLOUD" == "Azure" ] && TF_DEPLOYMENT="azure"
[ "$PCF_DEPLOYMENT_CLOUD" == "GCP" ] && TF_DEPLOYMENT="gcp"

#checkCloudCLI
#checkOpsMantools

TF_PATH=${TF_WORKDIR}/cf-terraform-${TF_DEPLOYMENT}/terraforming-${PRODUCT_TILE}
SSH_OPSMAN="ssh -qi /tmp/opsman.pem ubuntu@pcf.$PCF_DEPLOYMENT_ENV_NAME.$AWS_HOSTED_DNS_DOMAIN"

echo "PCF_DEPLOYMENT_CLOUD:$PCF_DEPLOYMENT_CLOUD"
if [ "${PCF_DEPLOYMENT_CLOUD}" == "AWS" ]; then
echo "$SSH_OPSMAN -n ls -la /tmp/"
  $SSH_OPSMAN -n "ls -la /tmp/"
  $SSH_OPSMAN -n "sh /tmp/debug.sh" | grep running | awk '{ print $(NF-2) }'

  exit
fi




#ssh -qi /home/ubuntu/workspace/cf-terraform-aws/terraforming-pas/opsman.pem ubuntu@pcf.awspas.pcfsdu.com -n "sh /tmp/debug.sh" | grep running | awk '{ print $(NF-2) }'

##############################################################################################
###################################### SSL VERIFICATION ######################################
##############################################################################################





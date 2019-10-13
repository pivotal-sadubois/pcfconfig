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

if [ "${PCF_DEPLOYMENT_CLOUD}" == "AWS" ]; then
  messageTitle "Destroying VM instances" 
  vms=$($SSH_OPSMAN -n "sh /tmp/debug.sh 2>/dev/null" | grep running | awk '{ print $(NF-2) }' | egrep "^i-") 
  for ins in $vms; do
    messagePrint " - Terminate Instance:" "$ins"
    #aws --region $AWS_REGION ec2 terminate-instances --instance-ids $ins > /dev/null 2>&1
  done

  # --- TERMINATE REMAINING VMS IF NOT FOUND BY ABOVE COMMAND ---
  vms=$(aws ec2 --region $AWS_REGION describe-instances | \
        jq -r ".Reservations[].Instances[] | select(.KeyName == \"$PCF_DEPLOYMENT_ENV_NAME-ops-manager-key\").InstanceId")

    messagePrint " - Terminate Instance:" "$ins"
    #aws --region $AWS_REGION ec2 terminate-instances --instance-ids $ins > /dev/null 2>&1
  done

  messageTitle "Cleanup AWS Environment (Terraform Destroy)" 
fi
  
##############################################################################################
##################################### TERRAFORM DESTROY ######################################
##############################################################################################

echo gaga10
echo "$TF_PATH"
  cd $TF_PATH
exit
  messageTitle "--------------------------------------- TERRAFORM DEPLOYMENT ----------------------------------------------"
  terraform destroy -auto-approve >> /tmp/$$_log 2>&1; ret=$?
  tail -20 /tmp/$$_log
  messageTitle "-----------------------------------------------------------------------------------------------------------"

  if [ $ret -ne 0 ]; then
    echo "ERROR: Problem with teraform destroy"
  fi


#ssh -qi /home/ubuntu/workspace/cf-terraform-aws/terraforming-pas/opsman.pem ubuntu@pcf.awspas.pcfsdu.com -n "sh /tmp/debug.sh" | grep running | awk '{ print $(NF-2) }'






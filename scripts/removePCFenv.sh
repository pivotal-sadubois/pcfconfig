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

[ "$PCF_DEPLOYMENT_CLOUD" == "AWS" ] && TF_DEPLOYMENT="aws"
[ "$PCF_DEPLOYMENT_CLOUD" == "Azure" ] && TF_DEPLOYMENT="azure"
[ "$PCF_DEPLOYMENT_CLOUD" == "GCP" ] && TF_DEPLOYMENT="gcp"

#checkCloudCLI
#checkOpsMantools

TF_PATH=${TF_WORKDIR}/cf-terraform-${TF_DEPLOYMENT}/terraforming-${PRODUCT_TILE}
OPSMAN_PRIVATE_KEY=$TF_PATH//opsman.pem
SSH_OPSMAN="ssh -qi $OPSMAN_PRIVATE_KEY ubuntu@pcf.$PCF_DEPLOYMENT_ENV_NAME.$AWS_HOSTED_DNS_DOMAIN"

if [ "${PCF_DEPLOYMENT_CLOUD}" == "Azure" ]; then
  messagePrint " - Deleting all VM's in Ressource Group" "$PCF_DEPLOYMENT_ENV_NAME"
  az vm delete --yes --ids $(az vm list -g $PCF_DEPLOYMENT_ENV_NAME --query "[].id" -o tsv) > /dev/null 2>&1

  # --- DELETE HOSTED ZONE ---
  domain="$PCF_DEPLOYMENT_ENV_NAME.$AWS_HOSTED_DNS_DOMAIN"
  ZONE_ID=$(aws route53 list-hosted-zones-by-name --dns-name ${domain} | \
            jq -r ".HostedZones[] | select(.Name | scan(\"^$domain.\")).Id")

  if [ "${ZONE_ID}" != "" ]; then
    messagePrint " - Deleting DNS Hosted Zone:" "$ZONE_ID"
    route53deleteHostedZone $ZONE_ID
  fi
fi 

if [ "${PCF_DEPLOYMENT_CLOUD}" == "GCP" ]; then
  messageTitle "Destroying VM instances" 
  list=$(gcloud compute zones list | grep "${GCP_REGION}" | awk '{ print $1 }')
  GCP_AZ1=$(echo $list | awk '{ print $1 }')
  GCP_AZ2=$(echo $list | awk '{ print $2 }')
  GCP_AZ3=$(echo $list | awk '{ print $3 }')
  GCP_AVAILABILITY_ZONES="$GCP_AZ1,$GCP_AZ2,$GCP_AZ3"

  for tmp in $(gcloud compute instances list --zones="$GCP_AVAILABILITY_ZONES" --filter="name!='jump-${PCF_DEPLOYMENT_ENV_NAME}'" | \
              grep -v "NAME" | awk '{ printf("%s:%s\n",$1,$2)}'); do

    ins=$(echo $tmp | awk -F: '{ print $1 }')
    reg=$(echo $tmp | awk -F: '{ print $2 }')
    messagePrint " - Terminate Instance:" "$ins"
    gcloud compute instances delete $ins --zone $reg -q > /dev/null 2>&1
  done
fi

if [ "${PCF_DEPLOYMENT_CLOUD}" == "AWS" ]; then
  messageTitle "Destroying VM instances" 

  # --- MAKE SURE OPSMANAGER IS RUNNING ---
  #ops=$(aws ec2 --region $AWS_REGION describe-instances | \
  #      jq -r ".Reservations[].Instances[] | select(.KeyName == \"$PCF_DEPLOYMENT_ENV_NAME-ops-manager-key\").InstanceId")
  #vms=$($SSH_OPSMAN -n "sh /tmp/debug.sh 2>/dev/null" | grep running | awk '{ print $(NF-2) }' | egrep "^i-") 
  #for ins in $vms; do
  #  messagePrint " - Terminate Instance:" "$ins"
  #  #aws --region $AWS_REGION ec2 terminate-instances --instance-ids $ins > /dev/null 2>&1
  #done

  # --- TERMINATE REMAINING VMS IF NOT FOUND BY ABOVE COMMAND ---
  vms=$(aws ec2 --region $AWS_REGION describe-instances | \
        jq -r ".Reservations[].Instances[] | select(.KeyName == \"$PCF_DEPLOYMENT_ENV_NAME-ops-manager-key\").InstanceId")

  for ins in $vms; do
    messagePrint " - Terminate Instance:" "$ins"
    aws --region $AWS_REGION ec2 terminate-instances --instance-ids $ins > /dev/null 2>&1
  done

  messageTitle "Cleanup AWS Environment (Terraform Destroy)" 
fi
  
##############################################################################################
##################################### TERRAFORM DESTROY ######################################
##############################################################################################

if [ "${PCF_DEPLOYMENT_CLOUD}" == "AWS" ]; then
  AWS_LOCATION=A$WS_REGION
  ENV_NAME=$PCF_DEPLOYMENT_ENV_NAME

  cleanAWSlb

echo "Press key"; read x
echo "stop here"; exit 1

  cd $TF_PATH
  messageTitle "----------------------------------------- TERRAFORM DESTROY -----------------------------------------------"
  terraform destroy -auto-approve >> /tmp/$$_log 2>&1; ret=$?
  tail -20 /tmp/$$_log
  messageTitle "-----------------------------------------------------------------------------------------------------------"

  if [ $ret -ne 0 ]; then
    echo "ERROR: Teraform destroy failed"
  fi

  if [ -d ${TF_WORKDIR}/cf-terraform-${TF_DEPLOYMENT} ]; then
    rm -rf ${TF_WORKDIR}/cf-terraform-${TF_DEPLOYMENT}
  fi

  cleanAWS
fi

if [ "${PCF_DEPLOYMENT_CLOUD}" == "GCP" ]; then
  cd $TF_PATH
  messageTitle "----------------------------------------- TERRAFORM DESTROY -----------------------------------------------"
  terraform destroy -auto-approve >> /tmp/$$_log 2>&1; ret=$?
  tail -20 /tmp/$$_log
  messageTitle "-----------------------------------------------------------------------------------------------------------"

  if [ $ret -ne 0 ]; then
    echo "ERROR: Teraform destroy failed"
  fi

  if [ -d ${TF_WORKDIR}/cf-terraform-${TF_DEPLOYMENT} ]; then 
    rm -rf ${TF_WORKDIR}/cf-terraform-${TF_DEPLOYMENT}
  fi

  cleanGCP
fi

if [ "${PCF_DEPLOYMENT_CLOUD}" == "Azure" ]; then
  RG=$(az group exists --name $PCF_DEPLOYMENT_ENV_NAME)
  if [ "$RG" == "true" ]; then
    messagePrint " - No acrive deployment, deleting ressource group" "$PCF_DEPLOYMENT_ENV_NAME"
    az group delete --name $PCF_DEPLOYMENT_ENV_NAME --yes
  fi
fi

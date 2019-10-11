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
 
DEBUG=0
PAS_SRT=1
TF_WORKDIR="$(dirname ~/workspace)/$(basename ~/workspace)"

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

  if [ -f $GCP_SERVICE_ACCOUNT ]; then
    PRJ=$(cat $GCP_SERVICE_ACCOUNT | jq -r '.project_id')
    if [ "${PRJ}" == "$GCP_PROJECT" ]; then 
      echo "service_account_key = <<SERVICE_ACCOUNT_KEY"     >> $TF_VARFILE
      cat $GCP_SERVICE_ACCOUNT                               >> $TF_VARFILE
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

if [ "${PCF_DEPLOYMENT_CLOUD}" == "AWS" ]; then
  # --- GET AVAILABILITY ZONE FOR LOCATION ---
  AWS_AZ1=$(aws ec2 describe-availability-zones --region $AWS_REGION | jq -r '.AvailabilityZones[0].ZoneName')
  AWS_AZ2=$(aws ec2 describe-availability-zones --region $AWS_REGION | jq -r '.AvailabilityZones[1].ZoneName')
  AWS_AZ3=$(aws ec2 describe-availability-zones --region $AWS_REGION | jq -r '.AvailabilityZones[2].ZoneName')

  OPSMAN_IMAGE=$(getOpsManagerAMI $PCF_DEPLOYMENT_CLOUD $PCF_OPSMANAGER_VERSION)

  echo "env_name           = \"${PCF_DEPLOYMENT_ENV_NAME}\""                   >> $TF_VARFILE
  echo "access_key         = \"${AWS_ACCESS_KEY}\""                            >> $TF_VARFILE
  echo "secret_key         = \"${AWS_SECRET_KEY}\""                            >> $TF_VARFILE
  echo "region             = \"${AWS_REGION}\""                                >> $TF_VARFILE
  echo "availability_zones = [\"${AWS_AZ1}\", \"${AWS_AZ2}\", \"${AWS_AZ3}\"]" >> $TF_VARFILE
  echo "ops_manager_ami    = \"${OPSMAN_IMAGE}\""                              >> $TF_VARFILE
  echo "dns_suffix         = \"${AWS_HOSTED_DNS_DOMAIN}\""                     >> $TF_VARFILE
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
fi

if [ "${PCF_DEPLOYMENT_CLOUD}" == "Azure" ]; then 
  OPSMAN_IMAGE=$(getOpsManagerAMI $PCF_DEPLOYMENT_CLOUD $PCF_OPSMANAGER_VERSION)

  echo "subscription_id       = \"${AZURE_SUBSCRIPTION_ID}\""                  >> $TF_VARFILE
  echo "tenant_id             = \"${AZURE_TENANT_ID}\""                        >> $TF_VARFILE
  echo "client_id             = \"${AZURE_CLIENT_ID}\""                        >> $TF_VARFILE
  echo "client_secret         = \"${AZURE_CLIENT_SECRET}\""                    >> $TF_VARFILE
  echo ""                                                                      >> $TF_VARFILE
  echo "env_name              = \"${PCF_DEPLOYMENT_ENV_NAME}\""                >> $TF_VARFILE
  echo "env_short_name        = \"${PRODUCT_TILE}\""                           >> $TF_VARFILE
  echo "location              = \"${AZURE_REGION}\""                           >> $TF_VARFILE
  echo "ops_manager_image_uri = \"${OPSMAN_IMAGE}\""                           >> $TF_VARFILE
  echo "dns_suffix            = \"${AWS_HOSTED_DNS_DOMAIN}\""                  >> $TF_VARFILE
  echo "vm_admin_username     = \"opsman\""                                    >> $TF_VARFILE

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
fi

##############################################################################################
########################### CLEANUP IF OPSMAN IS NOT RUNNING  ################################
##############################################################################################

if [ "${PCF_DEPLOYMENT_CLOUD}" == "AWS" ]; then
  TF_STATE=${TF_WORKDIR}/cf-terraform-${TF_DEPLOYMENT}/terraforming-${PRODUCT_TILE}/terraform.tfstate

  if [ -f ${TF_STATE} ]; then 
    AWS_OPSMAN_INSTANCE_ID=$(jq -r '.modules[].resources."aws_eip.ops_manager_attached".primary.attributes.instance' $TF_STATE | \
                           grep -v null)
    ins=$(aws ec2 --region=$AWS_REGION describe-instances --instance-ids $AWS_OPSMAN_INSTANCE_ID | \
          jq -r ".Reservations[].Instances[].InstanceId" | head -1) 
    if [ "${ins}" != "" ]; then 
      echo "Verify recent Deployment"
      messagePrint "Last deployment does not exist anymore" "$AWS_OPSMAN_INSTANCE_ID"
      messagePrint "Remove old Terraform Lock files" "${TF_WORKDIR}/cf-terraform-${TF_DEPLOYMENT}"

      rm -f ${TF_WORKDIR}/cf-terraform-${TF_DEPLOYMENT}
    fi
  fi
fi


TERRAFORM_RELEASE_NOTES=${PCFPATH}/files/terraform-release-notes.txt
PCFCONFIG_TF_STATE="${TF_WORKDIR}/cf-terraform-${TF_DEPLOYMENT}/terraforming-${PRODUCT_TILE}/.pcfconfig-terraform"
PCFCONFIG_OPSMAN_STATE="${TF_WORKDIR}/cf-terraform-${TF_DEPLOYMENT}/terraforming-${PRODUCT_TILE}/.pcfconfig-opsman"
PCFCONFIG_PKS_STATE="${TF_WORKDIR}/cf-terraform-${TF_DEPLOYMENT}/terraforming-${PRODUCT_TILE}/.pcfconfig-pks"
PCFCONFIG_PAS_STATE="${TF_WORKDIR}/cf-terraform-${TF_DEPLOYMENT}/terraforming-${PRODUCT_TILE}/.pcfconfig-pas"
PCFCONFIG_PKS_AUTH_STATE="${TF_WORKDIR}/cf-terraform-${TF_DEPLOYMENT}/terraforming-${PRODUCT_TILE}/.pcfconfig-pks-setup"
PCFCONFIG_PAS_AUTH_STATE="${TF_WORKDIR}/cf-terraform-${TF_DEPLOYMENT}/terraforming-${PRODUCT_TILE}/.pcfconfig-pas-setup"
PCFCONFIG_PKS_DEBUG="${TF_WORKDIR}/cf-terraform-${TF_DEPLOYMENT}/terraforming-${PRODUCT_TILE}/.pcfconfig-pas-debug"
PCFCONFIG_PAS_DEBUG="${TF_WORKDIR}/cf-terraform-${TF_DEPLOYMENT}/terraforming-${PRODUCT_TILE}/.pcfconfig-pks-debug"

# --- INITIALIZE STATE FILES ---
#touch $PCFCONFIG_TF_STATE $PCFCONFIG_OPSMAN_STATE $PCFCONFIG_PKS_STATE $PCFCONFIG_PAS_STATE

# --- ONLY EXECUTE IF STATUS OF LAST RUNN IS NOT 'completed' ---
if [ "$(getPCFconfigState $PCFCONFIG_TF_STATE)" != "completed" ]; then 
  setPCFconfigState $PCFCONFIG_TF_STATE "started"

  ${PCFPATH}/modules/pcfconfig-terraform --pivnet-token $PCF_PIVNET_TOKEN \
                                        $TF_TILE_OPTION $TF_VARFILE \
                                        --deployment $TF_DEPLOYMENT \
                                        --cf-version $PCF_OPSMANAGER_VERSION \
                                        --directory-prefix cf-terraform \
                                        --install-mode delete --no-ask \
                                        --tf-template $PCF_TERRAFORMS_TEMPLATE_VERSION \
                                        --aws-route53 $AWS_HOSTED_ZONE_ID
echo "deployPCFremote gaga1"
  if [ $? -ne 0 ]; then 
    setPCFconfigState $PCFCONFIG_TF_STATE "failed"
    echo "ERROR: Problem with pcfconfig-terraform occured"; exit 1
    exit 1
  fi

  cd ${TF_WORKDIR}/cf-terraform-${TF_DEPLOYMENT}/terraforming-${PRODUCT_TILE}

  if [ "${PCF_DEPLOYMENT_CLOUD}" == "Azure" ]; then 
    cp main.tf main.tf.orig
    sed -i '/^provider "azurerm"/,/^}/{s/version = .*/version = "~> 1.33.1"/}' main.tf
  fi

  #cp /Users/sadubois/workspace/terraform/ops_manager.tf ${TF_WORKDIR}/cf-terraform-${TF_DEPLOYMENT}/modules/ops_manager

  echo "--------------------------------------- TERRAFORM DEPLOYMENT ----------------------------------------------"
  terraform init > /tmp/$$_log 2>&1
  terraform plan -out=plan >> /tmp/$$_log 2>&1
  terraform apply -auto-approve >> /tmp/$$_log 2>&1; ret=$?
  tail -20 /tmp/$$_log
  echo "-----------------------------------------------------------------------------------------------------------"
  if [ $ret -ne 0 ]; then
    echo "ERROR: Problem with teraform apply"
    setPCFconfigState $PCFCONFIG_TF_STATE "failed"
    exit 1
  else
    setPCFconfigState $PCFCONFIG_TF_STATE "completed"
  fi
else
  messagePrint "pcfconfig-terraform already done" "skipping"
fi

# --- ONLY EXECUTE IF STATUS OF LAST RUNN IS NOT 'completed' ---
if [ "$(getPCFconfigState $PCFCONFIG_OPSMAN_STATE)" != "completed" ]; then 
  cd ${TF_WORKDIR}/cf-terraform-${TF_DEPLOYMENT}/terraforming-${PRODUCT_TILE}

  setPCFconfigState $PCFCONFIG_OPSMAN_STATE "started"
  ${PCFPATH}/modules/pcfconfig-opsman -u $PCF_OPSMANAGER_ADMIN_USER -p $PCF_OPSMANAGER_ADMIN_PASS \
       --deployment $TF_DEPLOYMENT \
       -dp $PCF_OPSMANAGER_DECRYPTION_KEY --aws-route53 $AWS_HOSTED_ZONE_ID --opsman-template $PCF_OPSMANAGER_CONFIG

  if [ $? -ne 0 ]; then
    setPCFconfigState $PCFCONFIG_OPSMAN_STATE "failed"
    echo "ERROR: Problem with pcfconfig-opsman occured"; exit 1
  else
    setPCFconfigState $PCFCONFIG_OPSMAN_STATE "completed"
  fi
else
  messagePrint "pcfconfig-opsman already done" "skipping"
fi

if [ "${PRODUCT_TILE}" == "pks" ]; then
  # --- ONLY EXECUTE IF STATUS OF LAST RUNN IS NOT 'completed' ---
  if [ "$(getPCFconfigState $PCFCONFIG_PKS_STATE)" != "completed" ]; then 
    cd ${TF_WORKDIR}/cf-terraform-${TF_DEPLOYMENT}/terraforming-${PRODUCT_TILE}

    setPCFconfigState $PCFCONFIG_PKS_STATE "started"

    if [ "${TLS_CERTIFICATE}" != "" -a "${TLS_PRIVATE_KEY}" != "" -a "${TLS_ROOT_CERT}" != "" ]; then
      ${PCFPATH}/modules/pcfconfig-pks -u $PCF_OPSMANAGER_ADMIN_USER  -p $PCF_OPSMANAGER_ADMIN_PASS \
        --pivnet-token "$PCF_PIVNET_TOKEN" --pks-template $PCF_TILE_PKS_CONFIG \
        --stemcell-version "$PCF_TILE_PKS_STEMCELL_VERSION" --stemcell-type "$PCF_TILE_PKS_STEMCELL_TYPE" \
        --pks-version $PCF_TILE_PKS_VERSION --aws-route53 $AWS_HOSTED_ZONE_ID \
        --deployment $TF_DEPLOYMENT \
        --tls_cert $TLS_CERTIFICATE --tls_private_key $TLS_PRIVATE_KEY --tls_root_cert $TLS_ROOT_CERT
    else
      ${PCFPATH}/modules/pcfconfig-pks -u $PCF_OPSMANAGER_ADMIN_USER  -p $PCF_OPSMANAGER_ADMIN_PASS \
        --pivnet-token "$PCF_PIVNET_TOKEN" --pks-template $PCF_TILE_PKS_CONFIG \
        --stemcell-version "$PCF_TILE_PKS_STEMCELL_VERSION" --stemcell-type "$PCF_TILE_PKS_STEMCELL_TYPE" \
        --deployment $TF_DEPLOYMENT \
        --pks-version $PCF_TILE_PKS_VERSION --aws-route53 $AWS_HOSTED_ZONE_ID
    fi
  
    if [ $? -ne 0 ]; then
      setPCFconfigState $PCFCONFIG_PKS_STATE "failed"
      echo "ERROR: Problem with pcfconfig-pks occured"; exit 1
    else
      setPCFconfigState $PCFCONFIG_PKS_STATE "completed"
    fi
  else
    messagePrint "pcfconfig-pks already done" "skipping"
  fi

  # --- ONLY EXECUTE IF STATUS OF LAST RUNN IS NOT 'completed' ---
  if [ "$(getPCFconfigState $PCFCONFIG_PKS_AUTH_STATE)" != "completed" ]; then 
    cd ${TF_WORKDIR}/cf-terraform-${TF_DEPLOYMENT}/terraforming-${PRODUCT_TILE}

    PKS_CLUSTER_1_PLAN="-"; PKS_CLUSTER_1_NAME="-"
    PKS_CLUSTER_2_PLAN="-"; PKS_CLUSTER_2_NAME="-"
    PKS_CLUSTER_3_PLAN="-"; PKS_CLUSTER_3_NAME="-"

    if [ "${PCF_TILE_PKS_CLUSTER_CL1_PLAN}" != "" ]; then 
      PKS_CLUSTER_1_PLAN=$PCF_TILE_PKS_CLUSTER_CL1_PLAN
      PKS_CLUSTER_1_NAME=cl1
    fi

    if [ "${PCF_TILE_PKS_CLUSTER_CL2_PLAN}" != "" ]; then 
      PKS_CLUSTER_2_PLAN=$PCF_TILE_PKS_CLUSTER_CL2_PLAN
      PKS_CLUSTER_2_NAME=cl2
    fi

    if [ "${PCF_TILE_PKS_CLUSTER_CL3_PLAN}" != "" ]; then 
      PKS_CLUSTER_3_PLAN=$PCF_TILE_PKS_CLUSTER_CL3_PLAN
      PKS_CLUSTER_3_NAME=cl3
    fi

    setPCFconfigState $PCFCONFIG_PKS_AUTH_STATE "started"
    ${PCFPATH}/modules/pcfconfig-pks-setup -u $PCF_OPSMANAGER_ADMIN_USER -p $PCF_OPSMANAGER_ADMIN_PASS \
         --deployment $TF_DEPLOYMENT \
         --pks-admin-user $PCF_TILE_PKS_ADMIN_USER  --pks-admin-pass $PCF_TILE_PKS_ADMIN_PASS \
         --pks-admin-mail $PCF_TILE_PKS_ADMIN_EMAIL --aws-route53 $AWS_HOSTED_ZONE_ID \
         --pks-cluster-1-name $PKS_CLUSTER_1_NAME \
         --pks-cluster-1-plan $PKS_CLUSTER_1_PLAN \
         --pks-cluster-2-name $PKS_CLUSTER_2_NAME \
         --pks-cluster-2-plan $PKS_CLUSTER_2_PLAN \
         --pks-cluster-3-name $PKS_CLUSTER_3_NAME \
         --pks-cluster-3-plan $PKS_CLUSTER_3_PLAN 

    if [ $? -ne 0 ]; then
      setPCFconfigState $PCFCONFIG_PKS_AUTH_STATE "failed"
      echo "ERROR: Problem with pcfconfig-pks-setup occured"; exit 1
    else
      setPCFconfigState $PCFCONFIG_PKS_AUTH_STATE "completed"
    fi
  else
    messagePrint "pcfconfig-pks-setup already done" "skipping"
  fi

  # --- ONLY EXECUTE IF STATUS OF LAST RUNN IS 'completed' ---
  cd ${TF_WORKDIR}/cf-terraform-${TF_DEPLOYMENT}/terraforming-${PRODUCT_TILE}

  PKS_CLUSTER_1_PLAN="-"; PKS_CLUSTER_1_NAME="-"
  PKS_CLUSTER_2_PLAN="-"; PKS_CLUSTER_2_NAME="-"
  PKS_CLUSTER_3_PLAN="-"; PKS_CLUSTER_3_NAME="-"

  if [ "${PCF_TILE_PKS_CLUSTER_CL1_PLAN}" != "" ]; then
    PKS_CLUSTER_1_PLAN=$PCF_TILE_PKS_CLUSTER_CL1_PLAN
    PKS_CLUSTER_1_NAME=cl1
  fi

  if [ "${PCF_TILE_PKS_CLUSTER_CL2_PLAN}" != "" ]; then
    PKS_CLUSTER_2_PLAN=$PCF_TILE_PKS_CLUSTER_CL2_PLAN
    PKS_CLUSTER_2_NAME=cl2
  fi

  if [ "${PCF_TILE_PKS_CLUSTER_CL3_PLAN}" != "" ]; then
    PKS_CLUSTER_3_PLAN=$PCF_TILE_PKS_CLUSTER_CL3_PLAN
    PKS_CLUSTER_3_NAME=cl3
  fi

  ${PCFPATH}/modules/pcfconfig-pks-debug --pks-admin-user $PCF_TILE_PKS_ADMIN_USER \
       --pks-admin-pass $PCF_TILE_PKS_ADMIN_PASS --deployment $TF_DEPLOYMENT \
       --pks-admin-mail $PCF_TILE_PKS_ADMIN_EMAIL --aws-route53 $AWS_HOSTED_ZONE_ID \
       --pks-cluster-1-name $PKS_CLUSTER_1_NAME \
       --pks-cluster-1-plan $PKS_CLUSTER_1_PLAN \
       --pks-cluster-2-name $PKS_CLUSTER_2_NAME \
       --pks-cluster-2-plan $PKS_CLUSTER_2_PLAN \
       --pks-cluster-3-name $PKS_CLUSTER_3_NAME \
       --pks-cluster-3-plan $PKS_CLUSTER_3_PLAN


else
  # --- ONLY EXECUTE IF STATUS OF LAST RUNN IS NOT 'completed' ---
  if [ "$(getPCFconfigState $PCFCONFIG_PAS_STATE)" != "completed" ]; then
    cd ${TF_WORKDIR}/cf-terraform-${TF_DEPLOYMENT}/terraforming-${PRODUCT_TILE}

    setPCFconfigState $PCFCONFIG_PAS_STATE "started"

    if [ "${TLS_CERTIFICATE}" != "" -a "${TLS_PRIVATE_KEY}" != "" -a "${TLS_ROOT_CERT}" != "" ]; then 
      ${PCFPATH}/modules/pcfconfig-pas -u $PCF_OPSMANAGER_ADMIN_USER  -p $PCF_OPSMANAGER_ADMIN_PASS --pivnet-token "$PCF_PIVNET_TOKEN" \
        --pas-version $PCF_TILE_PAS_VERSION --aws-route53 $AWS_HOSTED_ZONE_ID $PAS_SRT \
        --stemcell-version "$PCF_TILE_PAS_STEMCELL_VERSION" --stemcell-type "$PCF_TILE_PAS_STEMCELL_TYPE" \
        --pas-template $PCF_TILE_PAS_CONFIG --deployment $TF_DEPLOYMENT --pas-slug $PCF_TILE_PAS_SLUG \
        --tls_cert $TLS_CERTIFICATE --tls_private_key $TLS_PRIVATE_KEY --tls_root_cert $TLS_ROOT_CERT
    else
      ${PCFPATH}/modules/pcfconfig-pas -u $PCF_OPSMANAGER_ADMIN_USER  -p $PCF_OPSMANAGER_ADMIN_PASS --pivnet-token "$PCF_PIVNET_TOKEN" \
        --stemcell-version "$PCF_TILE_PAS_STEMCELL_VERSION" --stemcell-type "$PCF_TILE_PAS_STEMCELL_TYPE" \
        --pas-template $PCF_TILE_PAS_CONFIG --deployment $TF_DEPLOYMENT --pas-slug $PCF_TILE_PAS_SLUG \
        --pas-version $PCF_TILE_PAS_VERSION --aws-route53 $AWS_HOSTED_ZONE_ID $PAS_SRT
    fi

    if [ $? -ne 0 ]; then
      setPCFconfigState $PCFCONFIG_PAS_STATE "failed"
      echo "ERROR: Problem with pcfconfig-pas occured"; exit 1
    else
      setPCFconfigState $PCFCONFIG_PAS_STATE "completed"
    fi
  else
    messagePrint "pcfconfig-pas already done" "skipping"
  fi

  # --- ONLY EXECUTE IF STATUS OF LAST RUNN IS NOT 'completed' ---
  if [ "$(getPCFconfigState $PCFCONFIG_PAS_AUTH_STATE)" != "completed" ]; then
    cd ${TF_WORKDIR}/cf-terraform-${TF_DEPLOYMENT}/terraforming-${PRODUCT_TILE}

    setPCFconfigState $PCFCONFIG_PAS_AUTH_STATE "started"
    ${PCFPATH}/modules/pcfconfig-pas-setup -u $PCF_OPSMANAGER_ADMIN_USER -p $PCF_OPSMANAGER_ADMIN_PASS --pas-admin-user $PCF_TILE_PAS_ADMIN_USER \
         --pas-admin-pass $PCF_TILE_PAS_ADMIN_PASS --pas-admin-mail $PCF_TILE_PAS_ADMIN_EMAIL --deployment $TF_DEPLOYMENT 

    if [ $? -ne 0 ]; then
      setPCFconfigState $PCFCONFIG_PAS_AUTH_STATE "failed"
      echo "ERROR: Problem with pcfconfig-pas-setup occured"; exit 1
    else
      setPCFconfigState $PCFCONFIG_PAS_AUTH_STATE "completed"
    fi
  else
    messagePrint "pcfconfig-pas-setup already done" "skipping"
  fi

  # --- ONLY EXECUTE IF STATUS OF LAST RUNN IS 'completed' ---
  cd ${TF_WORKDIR}/cf-terraform-${TF_DEPLOYMENT}/terraforming-${PRODUCT_TILE}

  ${PCFPATH}/modules/pcfconfig-pas-debug -u $PCF_OPSMANAGER_ADMIN_USER -p $PCF_OPSMANAGER_ADMIN_PASS \
       --pas-admin-user $PCF_TILE_PAS_ADMIN_USER --pas-admin-pass $PCF_TILE_PAS_ADMIN_PASS \
       --pas-admin-mail $PCF_TILE_PAS_ADMIN_EMAIL --deployment $TF_DEPLOYMENT 

fi










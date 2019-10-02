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

export PATH=~/workspace/pcfconfig:~/pcfconfig:$PATH

PCFCONFIG_PATH=$(dirname $0)
PCFCONFIG_BASE=$(basename $0)

# --- SOURCE FUNCTIONS---
. ${PCFCONFIG_PATH}/../functions
. $envFile
 
DEBUG=0
TF_WORKDIR="$(dirname ~/workspace)/$(basename ~/workspace)"

echo "AWS_HOSTED_ZONE_ID:$AWS_HOSTED_ZONE_ID"
echo "AWS_HOSTED_DNS_DOMAIN:$AWS_HOSTED_DNS_DOMAIN"
exit

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
  echo "DNS_DOMAIN:$DNS_DOMAIN"
  echo "CLOUD_PROVIDER:$CLOUD_PROVIDER"
  echo "PRODUCT_TILE:$PRODUCT_TILE"
fi

echo ""
echo "PCF Configuration Utility ($PCFCONFIG_BASE)"
echo "by Sacha Dubois, Pivotal Inc,"
echo "-----------------------------------------------------------------------------------------------------------"
TF_DEPLOYMENT=$CLOUD_PROVIDER
checkCloudCLI
checkOpsMantools

# --- VERIFY PRODUCT VERSION ---
if [ "$PRODUCT_TILE" == "pks" ]; then 
  PCF_RELEASE_NOTES=${PCFCONFIG_PATH}/files/opsman-pks-release-notes.txt
else
  PCF_RELEASE_NOTES=${PCFCONFIG_PATH}/files/opsman-pas-release-notes.txt
fi

cnt=$(echo $PCF_VERSION | awk -F'.' '{ print NF }')
if [ ${cnt} -ne 3 ]; then
  echo "ERROR: $PRODUCT_TILE_NAME Version ($PCF_VERSION) should be in the format x.y.z"; exit 1
fi

if [ -f ${PCF_RELEASE_NOTES} ]; then 
  cnt=$(egrep -c "^${PCF_VERSION}:${CLOUD_PROVIDER}:default" $PCF_RELEASE_NOTES)
  if [ ${cnt} -gt 0 ]; then 
    PCF_OPSMAN_VERS=$(egrep "^${PCF_VERSION}:${CLOUD_PROVIDER}:default" $PCF_RELEASE_NOTES | awk -F: '{ print $4 }' | head -1)
    PCF_OPSMAN_TYPE=$(echo "${PCF_OPSMAN_VERS}" | awk -F'.' '{ printf("%s.%s\n",$1,$2 )}')
    PCF_STEMCELL_TYPE=$(egrep "^${PCF_VERSION}:${CLOUD_PROVIDER}:default" $PCF_RELEASE_NOTES | awk -F: '{ print $6 }' | head -1)
    PCF_STEMCELL_VERS=$(egrep "^${PCF_VERSION}:${CLOUD_PROVIDER}:default" $PCF_RELEASE_NOTES | awk -F: '{ print $7 }' | head -1)
    PCF_DEFAULT_TEMPLATE=$(egrep "^${PCF_VERSION}:${CLOUD_PROVIDER}:default" $PCF_RELEASE_NOTES | awk -F: '{ print $8 }')

    if [ "${PCF_DEFAULT_TEMPLATE}" == "" -o "${PCF_DEFAULT_TEMPLATE}" == "-" ]; then 
      echo "ERROR: There is currently no tested release for $PRODUCT_TILE_NAME $PCF_VERSION on $CLOUD_PROVIDER"; exit
    fi
  else
    echo "ERROR: $PRODUCT_TILE_NAME Release $PCF_VERSION not defined in $PCF_RELEASE_NOTES"; exit 1
  fi
else
  echo "ERROR: can not find ${PCF_RELEASE_NOTES} file"; exit 1
fi

##############################################################################################
######################################### PREPERATION ########################################
##############################################################################################

if [ "${CLOUD_PROVIDER}" == "gcp" ]; then 
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
OPSMAN_RELEASE_NOTES=${PCFCONFIG_PATH}/files/opsman-release-notes.txt
TF_VARFILE="/tmp/terraform_${CLOUD_PROVIDER}.tfvars"; rm -f $TF_VARFILE; touch $TF_VARFILE

# --- REGION FIX ---
if [ "${CLOUD_PROVIDER}" == "gcp" ]; then 
  cnt=$(echo "$GCP_REGION" | grep -c "europe")
  if [ $cnt -gt 0 ]; then SEARCH_REG="eu"; fi
  cnt=$(echo "$GCP_REGION" | grep -c "asia")
  if [ $cnt -gt 0 ]; then SEARCH_REG="asia"; fi
  cnt=$(echo "$GCP_REGION" | egrep -c "northamerica|us")
  if [ $cnt -gt 0 ]; then SEARCH_REG="us"; fi
fi

if [ "${CLOUD_PROVIDER}" == "aws" ]; then 
  SEARCH_REG="$AWS_REGION"
fi 

if [ "${CLOUD_PROVIDER}" == "azure" ]; then 
  cnt=$(echo "$AZURE_REGION" | egrep -c "europe")
  if [ $cnt -gt 0 ]; then SEARCH_REG="west_europe"; fi
  cnt=$(echo "$AZURE_REGION" | egrep -c "_us")
  if [ $cnt -gt 0 ]; then SEARCH_REG="east_us"; fi
  cnt=$(echo "$AZURE_REGION" | egrep -c "_asia")
  if [ $cnt -gt 0 ]; then SEARCH_REG="southeast_asia"; fi
fi

cnt=$(egrep "^(${PCF_OPSMAN_VERS}|${PCF_OPSMAN_VERS}.[0-9]*)," $OPSMAN_RELEASE_NOTES | grep -c ",${CLOUD_PROVIDER},")
if [ ${cnt} -gt 0 ]; then
  # --- CHECK OPSMAN VERSION ---
  cnt=$(egrep "^(${PCF_OPSMAN_VERS}|${PCF_OPSMAN_VERS}.[0-9]*)," $OPSMAN_RELEASE_NOTES | grep -c ",${CLOUD_PROVIDER},${AWS_REGION},")
  if [ ${cnt} -gt 0 ]; then
    OPSMAN_IMAGE=$(egrep "^(${PCF_OPSMAN_VERS}|${PCF_OPSMAN_VERS}.[0-9]*)," $OPSMAN_RELEASE_NOTES | \
                 grep ",${CLOUD_PROVIDER},${AWS_REGION}," | head -1 | awk -F',' '{ print $5 }')
  else
    OPSMAN_IMAGE=$(egrep "^(${PCF_OPSMAN_VERS}|${PCF_OPSMAN_VERS}.[0-9]*)," $OPSMAN_RELEASE_NOTES | \
                 grep ",${CLOUD_PROVIDER}," | head -1 | awk -F',' '{ print $5 }')
  fi
else
  echo "ERROR: Can not find configuration for OpsManager $PCF_OPSMAN_VERS in $OPSMAN_RELEASE_NOTES"; exit 1
fi

if [ "${CLOUD_PROVIDER}" == "gcp" ]; then
  list=$($GCLOUD compute zones list | grep "${GCP_REGION}" | awk '{ print $1 }')
  GCP_AZ1=$(echo $list | awk '{ print $1 }')
  GCP_AZ2=$(echo $list | awk '{ print $2 }')
  GCP_AZ3=$(echo $list | awk '{ print $3 }')

  echo "env_name           = \"${ENV_NAME}\""                                  >> $TF_VARFILE
  echo "region             = \"${GCP_REGION}\""                                >> $TF_VARFILE
  echo "zones              = [\"${GCP_AZ1}\", \"${GCP_AZ2}\", \"${GCP_AZ3}\"]" >> $TF_VARFILE
  echo "opsman_image_url   = \"${OPSMAN_IMAGE}\""                              >> $TF_VARFILE
  echo "dns_suffix         = \"${DNS_DOMAIN}\""                                >> $TF_VARFILE
  echo "project            = \"${GCP_PROJECT}\""                               >> $TF_VARFILE
  echo ""                                                                      >> $TF_VARFILE
  echo "ssl_cert = <<SSL_CERT"                                                 >> $TF_VARFILE
  echo "SSL_CERT"                                                              >> $TF_VARFILE
  echo ""                                                                      >> $TF_VARFILE
  echo "ssl_private_key = <<SSL_KEY"                                           >> $TF_VARFILE
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


if [ "${CLOUD_PROVIDER}" == "aws" ]; then
  # --- GET AVAILABILITY ZONE FOR LOCATION ---
  AWS_AZ1=$(aws ec2 describe-availability-zones --region $AWS_REGION | jq -r '.AvailabilityZones[0].ZoneName')
  AWS_AZ2=$(aws ec2 describe-availability-zones --region $AWS_REGION | jq -r '.AvailabilityZones[1].ZoneName')
  AWS_AZ3=$(aws ec2 describe-availability-zones --region $AWS_REGION | jq -r '.AvailabilityZones[2].ZoneName')

  echo "env_name           = \"${ENV_NAME}\""                                  >> $TF_VARFILE
  echo "access_key         = \"${AWS_ACCESS_KEY}\""                            >> $TF_VARFILE
  echo "secret_key         = \"${AWS_SECRET_KEY}\""                            >> $TF_VARFILE
  echo "region             = \"${AWS_REGION}\""                                >> $TF_VARFILE
  echo "availability_zones = [\"${AWS_AZ1}\", \"${AWS_AZ2}\", \"${AWS_AZ3}\"]" >> $TF_VARFILE
  echo "ops_manager_ami    = \"${OPSMAN_IMAGE}\""                              >> $TF_VARFILE
  echo "dns_suffix         = \"${DNS_DOMAIN}\""                                >> $TF_VARFILE
  echo ""                                                                      >> $TF_VARFILE
  echo "ssl_cert = <<SSL_CERT"                                                 >> $TF_VARFILE

  if [ "$TLS_CERTIFICATE" != "" -a "${TLS_PRIVATE_KEY}" != "" ]; then 
    cat $TLS_CERTIFICATE >> $TF_VARFILE
  fi

  echo "SSL_CERT"                                                              >> $TF_VARFILE
  echo ""                                                                      >> $TF_VARFILE
  echo "ssl_private_key = <<SSL_KEY"                                           >> $TF_VARFILE

  if [ "$TLS_CERTIFICATE" != "" -a "${TLS_PRIVATE_KEY}" != "" ]; then 
    cat $TLS_PRIVATE_KEY >> $TF_VARFILE
  fi

  echo "SSL_KEY"                                                               >> $TF_VARFILE
fi

if [ "${CLOUD_PROVIDER}" == "azure" ]; then 
  echo "subscription_id       = \"${AZURE_SUBSCRIPTION_ID}\""                  >> $TF_VARFILE
  echo "tenant_id             = \"${AZURE_TENANT_ID}\""                        >> $TF_VARFILE
  echo "client_id             = \"${AZURE_CLIENT_ID}\""                        >> $TF_VARFILE
  echo "client_secret         = \"${AZURE_CLIENT_SECRET}\""                    >> $TF_VARFILE
  echo ""                                                                      >> $TF_VARFILE
  echo "env_name              = \"${ENV_NAME}\""                               >> $TF_VARFILE
  echo "env_short_name        = \"${PRODUCT_TILE}\""                           >> $TF_VARFILE
  echo "location              = \"${AZURE_REGION}\""                           >> $TF_VARFILE
  echo "ops_manager_image_uri = \"${OPSMAN_IMAGE}\""                           >> $TF_VARFILE
  echo "dns_suffix            = \"${DNS_DOMAIN}\""                             >> $TF_VARFILE
  echo "vm_admin_username     = \"opsman\""                                    >> $TF_VARFILE
fi

TERRAFORM_RELEASE_NOTES=${PCFCONFIG_PATH}/files/terraform-release-notes.txt
PCF_LATEST=$(egrep ":${PCF_OPSMAN_TYPE}" $TERRAFORM_RELEASE_NOTES | awk -F: '{ print $2 }' | head -1) 
PCFCONFIG_TF_STATE="${TF_WORKDIR}/cf-terraform-${CLOUD_PROVIDER}/terraforming-${PRODUCT_TILE}/.pcfconfig-terraform"
PCFCONFIG_OPSMAN_STATE="${TF_WORKDIR}/cf-terraform-${CLOUD_PROVIDER}/terraforming-${PRODUCT_TILE}/.pcfconfig-opsman"
PCFCONFIG_PKS_STATE="${TF_WORKDIR}/cf-terraform-${CLOUD_PROVIDER}/terraforming-${PRODUCT_TILE}/.pcfconfig-pks"
PCFCONFIG_PAS_STATE="${TF_WORKDIR}/cf-terraform-${CLOUD_PROVIDER}/terraforming-${PRODUCT_TILE}/.pcfconfig-pas"
PCFCONFIG_PKS_AUTH_STATE="${TF_WORKDIR}/cf-terraform-${CLOUD_PROVIDER}/terraforming-${PRODUCT_TILE}/.pcfconfig-pks-setup"
PCFCONFIG_PAS_AUTH_STATE="${TF_WORKDIR}/cf-terraform-${CLOUD_PROVIDER}/terraforming-${PRODUCT_TILE}/.pcfconfig-pas-setup"
PCFCONFIG_PKS_DEBUG="${TF_WORKDIR}/cf-terraform-${CLOUD_PROVIDER}/terraforming-${PRODUCT_TILE}/.pcfconfig-pas-debug"
PCFCONFIG_PAS_DEBUG="${TF_WORKDIR}/cf-terraform-${CLOUD_PROVIDER}/terraforming-${PRODUCT_TILE}/.pcfconfig-pks-debug"

if [ "${PCF_LATEST}" == "" ]; then 
  echo "ERROR: $0 No entry found for $PCF_OPSMAN_TYPE in $TERRAFORM_RELEASE_NOTES"
  exit 1
fi

# --- INITIALIZE STATE FILES ---
#touch $PCFCONFIG_TF_STATE $PCFCONFIG_OPSMAN_STATE $PCFCONFIG_PKS_STATE $PCFCONFIG_PAS_STATE

# --- ONLY EXECUTE IF STATUS OF LAST RUNN IS NOT 'completed' ---
if [ "$(getPCFconfigState $PCFCONFIG_TF_STATE)" != "completed" ]; then 
  setPCFconfigState $PCFCONFIG_TF_STATE "started"

  ${PCFCONFIG_PATH}/pcfconfig-terraform --pivnet-token $PCF_PIVNET_TOKEN \
                                        $TF_TILE_OPTION $TF_VARFILE \
                                        --deployment $CLOUD_PROVIDER \
                                        --cf-version $PCF_LATEST \
                                        --directory-prefix cf-terraform \
                                        --install-mode delete --no-ask \
                                        --aws-route53 $AWS_HOSTED_ZONE_ID
  if [ $? -ne 0 ]; then 
    setPCFconfigState $PCFCONFIG_TF_STATE "failed"
    echo "ERROR: Problem with pcfconfig-terraform occured"; exit 1
    exit 1
  fi

  cd ${TF_WORKDIR}/cf-terraform-${CLOUD_PROVIDER}/terraforming-${PRODUCT_TILE}

  if [ "${CLOUD_PROVIDER}" == "azure" ]; then 
    cp main.tf main.tf.orig
    sed -i '/^provider "azurerm"/,/^}/{s/version = .*/version = "~> 1.33.1"/}' main.tf
  fi

  #cp /Users/sadubois/workspace/terraform/ops_manager.tf ${TF_WORKDIR}/cf-terraform-${CLOUD_PROVIDER}/modules/ops_manager

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
  cd ${TF_WORKDIR}/cf-terraform-${CLOUD_PROVIDER}/terraforming-${PRODUCT_TILE}

  setPCFconfigState $PCFCONFIG_OPSMAN_STATE "started"
  pcfconfig-opsman -u $PCF_OPSMANAGER_ADMIN_USER -p $PCF_OPSMANAGER_ADMIN_PASS -dp $PCF_OPSMANAGER_DECRYPTION_KEY --aws-route53 $AWS_HOSTED_ZONE_ID 

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
    cd ${TF_WORKDIR}/cf-terraform-${CLOUD_PROVIDER}/terraforming-${PRODUCT_TILE}

    setPCFconfigState $PCFCONFIG_PKS_STATE "started"

    if [ "${TLS_CERTIFICATE}" != "" -a "${TLS_PRIVATE_KEY}" != "" -a "${TLS_ROOT_CERT}" != "" ]; then
      pcfconfig-pks -u $PCF_OPSMANAGER_ADMIN_USER  -p $PCF_OPSMANAGER_ADMIN_PASS --pivnet-token "$PCF_PIVNET_TOKEN" \
        --pks-version $PCF_TILE_PKS_VERSION --aws-route53 $AWS_HOSTED_ZONE_ID \
        --tls_cert $TLS_CERTIFICATE --tls_private_key $TLS_PRIVATE_KEY --tls_root_cert $TLS_ROOT_CERT
    else
      pcfconfig-pks -u $PCF_OPSMANAGER_ADMIN_USER  -p $PCF_OPSMANAGER_ADMIN_PASS --pivnet-token "$PCF_PIVNET_TOKEN" \
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
    cd ${TF_WORKDIR}/cf-terraform-${CLOUD_PROVIDER}/terraforming-${PRODUCT_TILE}

    [ "${PKS_CLUSTER_1_PLAN}" == "" ] && PKS_CLUSTER_1_PLAN="-"
    [ "${PKS_CLUSTER_2_PLAN}" == "" ] && PKS_CLUSTER_2_PLAN="-"
    [ "${PKS_CLUSTER_3_PLAN}" == "" ] && PKS_CLUSTER_3_PLAN="-"
    [ "${PKS_CLUSTER_1_NAME}" == "" ] && PKS_CLUSTER_1_NAME="-"
    [ "${PKS_CLUSTER_2_NAME}" == "" ] && PKS_CLUSTER_2_NAME="-"
    [ "${PKS_CLUSTER_3_NAME}" == "" ] && PKS_CLUSTER_3_NAME="-"
  
    setPCFconfigState $PCFCONFIG_PKS_AUTH_STATE "started"
    pcfconfig-pks-setup -u $PCF_OPSMANAGER_ADMIN_USER -p $PCF_OPSMANAGER_ADMIN_PASS \
         --pks-admin-user $PKS_ADMIN_USER --pks-admin-pass $PKS_ADMIN_PASS \
         --pks-admin-mail $PKS_ADMIN_MAIL --aws-route53 $AWS_HOSTED_ZONE_ID \
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
  cd ${TF_WORKDIR}/cf-terraform-${CLOUD_PROVIDER}/terraforming-${PRODUCT_TILE}
  [ "${PKS_CLUSTER_1_PLAN}" == "" ] && PKS_CLUSTER_1_PLAN="-"
  [ "${PKS_CLUSTER_2_PLAN}" == "" ] && PKS_CLUSTER_2_PLAN="-"
  [ "${PKS_CLUSTER_3_PLAN}" == "" ] && PKS_CLUSTER_3_PLAN="-"
  [ "${PKS_CLUSTER_1_NAME}" == "" ] && PKS_CLUSTER_1_NAME="-"
  [ "${PKS_CLUSTER_2_NAME}" == "" ] && PKS_CLUSTER_2_NAME="-"
  [ "${PKS_CLUSTER_3_NAME}" == "" ] && PKS_CLUSTER_3_NAME="-"

  pcfconfig-pks-debug --pks-admin-user $PKS_ADMIN_USER --pks-admin-pass $PKS_ADMIN_PASS \
       --pks-admin-mail $PKS_ADMIN_MAIL --aws-route53 $AWS_HOSTED_ZONE_ID \
       --pks-cluster-1-name $PKS_CLUSTER_1_NAME \
       --pks-cluster-1-plan $PKS_CLUSTER_1_PLAN \
       --pks-cluster-2-name $PKS_CLUSTER_2_NAME \
       --pks-cluster-2-plan $PKS_CLUSTER_2_PLAN \
       --pks-cluster-3-name $PKS_CLUSTER_3_NAME \
       --pks-cluster-3-plan $PKS_CLUSTER_3_PLAN


else
  # --- ONLY EXECUTE IF STATUS OF LAST RUNN IS NOT 'completed' ---
  if [ "$(getPCFconfigState $PCFCONFIG_PAS_STATE)" != "completed" ]; then
    cd ${TF_WORKDIR}/cf-terraform-${CLOUD_PROVIDER}/terraforming-${PRODUCT_TILE}

    setPCFconfigState $PCFCONFIG_PAS_STATE "started"

    if [ "${TLS_CERTIFICATE}" != "" -a "${TLS_PRIVATE_KEY}" != "" -a "${TLS_ROOT_CERT}" != "" ]; then 
      pcfconfig-pas -u $PCF_OPSMANAGER_ADMIN_USER  -p $PCF_OPSMANAGER_ADMIN_PASS --pivnet-token "$PCF_PIVNET_TOKEN" \
        --pas-version $PCF_TILE_PAS_VERSION --aws-route53 $AWS_HOSTED_ZONE_ID $PAS_SRT \
        --tls_cert $TLS_CERTIFICATE --tls_private_key $TLS_PRIVATE_KEY --tls_root_cert $TLS_ROOT_CERT
    else
      pcfconfig-pas -u $PCF_OPSMANAGER_ADMIN_USER  -p $PCF_OPSMANAGER_ADMIN_PASS --pivnet-token "$PCF_PIVNET_TOKEN" \
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
    cd ${TF_WORKDIR}/cf-terraform-${CLOUD_PROVIDER}/terraforming-${PRODUCT_TILE}

    setPCFconfigState $PCFCONFIG_PAS_AUTH_STATE "started"
    pcfconfig-pas-setup -u $PCF_OPSMANAGER_ADMIN_USER -p $PCF_OPSMANAGER_ADMIN_PASS --pas-admin-user $PAS_ADMIN_USER \
         --pas-admin-pass $PAS_ADMIN_PASS --pas-admin-mail $PAS_ADMIN_MAIL 

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
  cd ${TF_WORKDIR}/cf-terraform-${CLOUD_PROVIDER}/terraforming-${PRODUCT_TILE}

  pcfconfig-pas-debug -u $PCF_OPSMANAGER_ADMIN_USER -p $PCF_OPSMANAGER_ADMIN_PASS \
       --pas-admin-user $PAS_ADMIN_USER --pas-admin-pass $PAS_ADMIN_PASS \
       --pas-admin-mail $PAS_ADMIN_MAIL

fi










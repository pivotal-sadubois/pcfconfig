#!/bin/bash

if [ "$1" == "" ]; then 
  echo "USAGE: $0 <ops-manager-url> [object]"
  echo "        object:    staged/director/properties"
  echo "                   staged/director/iaas_configurations"
  echo "                   staged/director/availability_zones"
  echo "                   staged/director/network_and_az"
  echo "                   staged/director/networks"
  echo ""
  exit
fi

if [ -f ~/.pcfconfig ]; then 
  . ~/.pcfconfig
fi

if [ "${PCF_OPSMANAGER_ADMIN_USER}" == "" -a "${PCF_OPSMANAGER_ADMIN_PASS}" == "" ]; then 
  echo "ERROR: Please set the environment variables PCF_OPSMANAGER_ADMIN_USER and PCF_OPSMANAGER_ADMIN_PASS"
  exit 1
fi

export OM_TARGET=$1
export OM_OBJECT=$2
export OM_LOGIN="--skip-ssl-validation --target ${OM_TARGET} --username ${PCF_OPSMANAGER_ADMIN_USER} --password ${PCF_OPSMANAGER_ADMIN_PASS}"

echo "om $OM_LOGIN curl --path /api/v0/$2"

om $OM_LOGIN curl --path /api/v0/$2
exit

#om $OM_LOGIN curl --path /api/v0/staged/products
om $OM_LOGIN curl --path /api/v0/staged/products/harbor-container-registry-ac9f2d4223d6cce2eb4d//properties
exit
om $OM_LOGIN curl --path /api/v0/staged/director/properties

exit
om $OM_LOGIN curl --path /api/v0/staged/products/cf-f101b7d329dab332a79d/properties
om $OM_LOGIN curl --path /api/v0/staged/director/properties
om $OM_LOGIN curl --path /api/v0/staged/director/iaas_configurations/:guid
exit
om $OM_LOGIN curl --path /api/v0/staged/director/verifiers/install_time/AvailabilityZonesVerifier -d '{ "enabled": false }'
om $OM_LOGIN curl --path /api/v0/staged/director/verifiers/install_time
exit
om $OM_LOGIN curl --path /api/v0/staged/director/availability_zones
om $OM_LOGIN curl --path /api/v0/staged/director/iaas_configurations
om $OM_LOGIN curl --path /api/v0/staged/director/network_and_az
om $OM_LOGIN curl --path /api/v0/staged/director/networks
om $OM_LOGIN curl --path /api/v0/staged/director/properties
om $OM_LOGIN curl --path /api/v0/deployed/director/manifest
exit
#om $OM_LOGIN curl --path /api/v0/staged/director/properties
#om $OM_LOGIN curl --path /api/v0/deployed/director/credentials/uaa_admin_user_credentials
om $OM_LOGIN curl --path /api/v0/deployed/director/manifest
exit
om $OM_LOGIN curl --path /api/v0/deployed/products
om $OM_LOGIN curl --path /api/v0/deployed/products/pivotal-container-service-9c2f5b483dc211fec86a/properties
echo gaga
om $OM_LOGIN curl --path /api/v0/staged/products/
om $OM_LOGIN curl --path /api/v0/staged/products/pivotal-container-service-9c2f5b483dc211fec86a/properties
exit

#om $OM_LOGIN curl --path /api/v0/staged/director/availability_zones
#om $OM_LOGIN curl --path /api/v0/staged/director/iaas_configurations
#om $OM_LOGIN curl --path /api/v0/staged/director/network_and_az
#om $OM_LOGIN curl --path /api/v0/staged/director/networks
#om $OM_LOGIN curl --path /api/v0/staged/director/properties
#om $OM_LOGIN curl --path /api/v0/staged/products

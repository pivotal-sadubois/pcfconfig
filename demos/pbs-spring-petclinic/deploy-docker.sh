#!/bin/bash
# ============================================================================================
# File: ........: deploy_demo.sh
# Language .....: bash
# Author .......: Sacha Dubois, Pivotal
# --------------------------------------------------------------------------------------------
# Description ..: Demonstration for PBS spring-petclinic based on two different URL
# ============================================================================================

BASENAME=$(basename $0)
DIRNAME=$(dirname $0)

if [ -f ${DIRNAME}/../../functions ]; then 
  . ${DIRNAME}/../../functions
else
  echo "ERROR: can ont find ${DIRNAME}/../../functions"; exit 1
fi

# --- CHECK ENVIRONMENT VARIABLES ---
if [ -f ~/.pcfconfig ]; then
  . ~/.pcfconfig
fi

# --- LOAD CLOUD ENVIRONMENT ---
dom=$(pks cluster cl1 | grep "Kubernetes Master Host" | awk '{ print $NF }' | sed 's/cl1\.//g')

# Created by /usr/local/bin/figlet
clear
echo '                                                                                      '
echo '           ____             _               ____          _    ____ _ _       _       '
echo '          / ___| _ __  _ __(_)_ __   __ _  |  _ \ ___  __| |  / ___| (_)_ __ (_) ___  '
echo '          \___ \|  _ \|  __| |  _ \ / _  | | |_) / _ \/ _  | | |   | | |  _ \| |/ __| '
echo '           ___) | |_) | |  | | | | | (_| | |  __/  __/ (_| | | |___| | | | | | | (__  '
echo '          |____/| .__/|_|  |_|_| |_|\__, | |_|   \___|\__,_|  \____|_|_|_| |_|_|\___| '
echo '                |_|                 |___/                                             '
echo '                                                                                      '
echo '                                   ____                                               '
echo '                                  |  _ \  ___ _ __ ___   ___                          '
echo '                                  | | | |/ _ \  _   _ \ / _ \                         '
echo '                                  | |_| |  __/ | | | | | (_) |                        '
echo '                                  |____/ \___|_| |_| |_|\___/                         '
echo '                                                                                      '
echo '          ----------------------------------------------------------------------------'
echo '                           Demonstration for Pivotal Build Service (PBS)              '
echo '                                    by Sacha Dubois, Pivotal Inc                      '
echo '          ----------------------------------------------------------------------------'
echo '                                                                                      '

showK8sEnvironment

if [ -f /tmp/deployPCFenv_${PKS_ENNAME} ]; then
  . /tmp/deployPCFenv_${PKS_ENNAME}
fi

if [ ! -f /usr/bin/pb ]; then 
  echo "ERROR: The /usr/bin/pb utility is not installed, please optain it from network.pivotal.io"
  exit
fi
missing_variables=0
if [ "${PCF_TILE_HARBOR_ADMIN_PASS}" == "" ]; then
  missing_variables=1
  echo ""
  echo "  MISSING ENVIRONMENT-VARIABES  DESCRIPTION        "
  echo "  --------------------------------------------------------------------------------------------------------------"

  if [ "${PCF_TILE_HARBOR_ADMIN_PASS}" == "" ]; then
    echo "  PCF_TILE_HARBOR_ADMIN_PASS    (required) Harbor Administrator Password"
  fi
else
  messageTitle "Pivotal Container Platform (Harbor)"
  messagePrint " - Harbor Version"                "$PCF_TILE_HARBOR_VERSION"
  messagePrint " - Harbor Administrator Password" "$PCF_TILE_HARBOR_ADMIN_PASS"
  echo ""
fi

if [ "${PCF_TILE_PBS_ADMIN_USER}" == "" -o "${PCF_TILE_PBS_ADMIN_PASS}" == "" -o "${PCF_TILE_PBS_DOCKER_REPO}" == "" -o \
     "${PCF_TILE_PBS_DOCKER_USER}" == "" -o "${PCF_TILE_PBS_DOCKER_PASS}" == "" -o "${PCF_TILE_PBS_GITHUB_REPO}" == "" -o \
     "${PCF_TILE_PBS_GITHUB_USER}" == "" -o "${PCF_TILE_PBS_GITHUB_PASS}" == "" ]; then
  missing_variables=1
  echo ""
  echo "  MISSING ENVIRONMENT-VARIABES  DESCRIPTION        "
  echo "  --------------------------------------------------------------------------------------------------------------"

  if [ "${PCF_TILE_PBS_ADMIN_USER}" == "" ]; then
    echo "  PCF_TILE_PBS_ADMIN_USER       (required) PBS Administrator User"
  fi

  if [ "${PCF_TILE_PBS_ADMIN_PASS}" == "" ]; then
    echo "  PCF_TILE_PBS_ADMIN_PASS       (required) PBS Administrator Password"
  fi

  if [ "${PCF_TILE_PBS_DOCKER_REPO}" == "" ]; then
    echo "  PCF_TILE_PBS_DOCKER_REPO      (required) Docker Repository Name"
  fi

  if [ "${PCF_TILE_PBS_DOCKER_USER}" == "" ]; then
    echo "  PCF_TILE_PBS_DOCKER_USER      (required) Docker Repository User"
  fi

  if [ "${PCF_TILE_PBS_DOCKER_PASS}" == "" ]; then
    echo "  PCF_TILE_PBS_DOCKER_PASS      (required) Docker Repository Password"
  fi

  if [ "${PCF_TILE_PBS_GITHUB_REPO}" == "" ]; then
    echo "  PCF_TILE_PBS_GITHUB_REPO      (required) GitHub Repository Name"
  fi

  if [ "${PCF_TILE_PBS_GITHUB_USER}" == "" ]; then
    echo "  PCF_TILE_PBS_GITHUB_USER      (required) GitHub Repository User"
  fi

  if [ "${PCF_TILE_PBS_GITHUB_PASS}" == "" ]; then
    echo "  PCF_TILE_PBS_GITHUB_PASS      (required) GitHub Repository Password"
  fi
  echo ""
else
  messageTitle "Pivotal Container Platform (PBS)"
  messagePrint " - PBS Version"                "$PCF_TILE_PBS_VERSION"
  messagePrint " - PBS Administrator User"     "$PCF_TILE_PBS_ADMIN_USER"
  messagePrint " - PBS Administrator Password" "$PCF_TILE_PBS_ADMIN_PASS"
  messagePrint " - Docker Repository Name"     "$PCF_TILE_PBS_DOCKER_REPO"
  messagePrint " - Docker Repository User"     "$PCF_TILE_PBS_DOCKER_USER"
  messagePrint " - Docker Repository Password" "$PCF_TILE_PBS_DOCKER_PASS"
  messagePrint " - GitHub Repository Name"     "$PCF_TILE_PBS_GITHUB_REPO"
  messagePrint " - GitHub Repository User"     "$PCF_TILE_PBS_GITHUB_USER"
  messagePrint " - GitHub Repository Password" "$PCF_TILE_PBS_GITHUB_PASS"
  echo ""
fi

if [ ${missing_variables} -eq 1 ]; then
  echo "  --------------------------------------------------------------------------------------------------------------"
  echo "  IMPORTANT: Please set the missing environment variables either in your shell or in the pcfconfig"
  echo "             configuration file ~/.pcfconfig and set all variables with the 'export' notation"
  echo "             ie. => export AZURE_PKS_TLS_CERTIFICATE=/home/demouser/certs/cert.pem"
  echo "  --------------------------------------------------------------------------------------------------------------"
  exit 1
fi


echo "registry: $PCF_TILE_PBS_DOCKER_REPO"    >  /tmp/docker.yml
echo "username: $PCF_TILE_PBS_DOCKER_USER"    >> /tmp/docker.yml
echo "password: $PCF_TILE_PBS_DOCKER_PASS"    >> /tmp/docker.yml

echo "registry: $PCF_TILE_PBS_GITHUB_REPO"    >  /tmp/github.yml
echo "username: $PCF_TILE_PBS_GITHUB_USER"    >> /tmp/github.yml
echo "password: $PCF_TILE_PBS_GITHUB_PASS"    >> /tmp/github.yml

prtHead "Set API Target for Pivotal Build Service (PBS)"
execCmd "pb api set https://build-service.apps-${PKS_CLNAME}.$PKS_ENNAME --skip-ssl-validation"

prtHead "Login to the Pivotal Build Service as '$PCF_TILE_PBS_ADMIN_USER' and pawword '$PCF_TILE_PBS_ADMIN_PASS'"
pb login
echo ""

prtHead "Create and select Project ped-clinic"
execCmd "pb project create ped-clinic"
execCmd "pb project target ped-clinic"

prtHead "Add screts for Docker Registry from (/tmp/docker.yml)" 
execCmd "cat /tmp/docker.yml"
execCmd "pb secrets registry apply -f /tmp/docker.yml"

prtHead "Add screts for Docker Registry from (/tmp/github.yml)" 
execCmd "cat /tmp/github.yml"
execCmd "pb secrets registry apply -f /tmp/github.yml"

prtHead "Create Image (spring-petclinic-docker.yml)"
execCmd "cat spring-petclinic-docker.yml"
execCmd "pb image apply -f spring-petclinic-docker.yml"
execCmd "pb image list"
sleep 10
execCmd "pb image logs ${PCF_TILE_PBS_DOCKER_REPO}/${PCF_TILE_PBS_DOCKER_USER}/spring-petclinic:latest -b 1 -f"

prtText "Login in to Docker Repository on your local workstartion and run pedclinic"
prtText " => sudo docker login harbor.${PCF_DEPLOYMENT_ENV_NAME}.${AWS_HOSTED_DNS_DOMAIN} -u admin -p pivotal"
prtText " => sudo docker run ${PCF_TILE_PBS_DOCKER_REPO}/${PCF_TILE_PBS_DOCKER_USER}/spring-petclinic:latest"

exit


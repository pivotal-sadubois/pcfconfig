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

variable_notice() {
  echo "  --------------------------------------------------------------------------------------------------------------"
  echo "  IMPORTANT: Please set the missing environment variables either in your shell or in the pcfconfig"
  echo "             configuration file ~/.pcfconfig and set all variables with the 'export' notation"
  echo "             ie. => export AZURE_PKS_TLS_CERTIFICATE=/home/demouser/certs/cert.pem"
  echo "  --------------------------------------------------------------------------------------------------------------"
  exit 1
}

# --- LOAD CLOUD ENVIRONMENT ---
dom=$(pks cluster cl1 | grep "Kubernetes Master Host" | awk '{ print $NF }' | sed 's/cl1\.//g')

# Created by /usr/local/bin/figlet
clear
echo '                                                                                      '
echo '            ____             _               ____      _      ____ _ _       _        '
echo '           / ___| _ __  _ __(_)_ __   __ _  |  _ \ ___| |_   / ___| (_)_ __ (_) ___   '
echo '           \___ \|  _ \|  __| |  _ \ / _  | | |_) / _ \ __| | |   | | |  _ \| |/ __|  '
echo '            ___) | |_) | |  | | | | | (_| | |  __/  __/ |_  | |___| | | | | | | (__   '
echo '           |____/| .__/|_|  |_|_| |_|\__, | |_|   \___|\__|  \____|_|_|_| |_|_|\___|  '
echo '                 |_|                 |___/                                            '
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

PB=$(which pb)
if [ "$PB" == "" ]; then
  echo "ERROR: The pb utility is not installed, please optain it from network.pivotal.io"
  exit
fi

missing_variables=0
GIT_PETCLIENTIC_SOURCE=https://github.com/spring-projects/spring-petclinic
if [ "${PCF_TILE_PBS_DEMO_PETCLINIC}" == "" ]; then
  echo ""
  echo "  MISSING ENVIRONMENT-VARIABES  DESCRIPTION        "
  echo "  --------------------------------------------------------------------------------------------------------------"
  echo ""

  if [ "${PCF_TILE_PBS_DEMO_PETCLINIC}" == "" -o "${PCF_TILE_PBS_DEMO_PETCLINIC}" == "$GIT_PETCLIENTIC_SOURCE" ]; then
    echo "  PCF_TILE_PBS_DEMO_PETCLINIC   (required) GIT Repository for the PetClinic Demo"
    echo ""
  fi

  variable_notice; exit 1
else
  messageTitle "  PBS Demo Settings (spring-petclinic)"
  messagePrint "   - GIT Repository for the PedClienic Demo" "$PCF_TILE_PBS_DEMO_PETCLINIC"
  echo ""

  if [ "${PCF_TILE_PBS_DEMO_PETCLINIC}" == "$GIT_PETCLIENTIC_SOURCE" ]; then
    echo "  PCF_TILE_PBS_DEMO_PETCLINIC   (required) GIT Repository for the PetClinic Demo"
    echo ""
    echo "  Please clone the GIT repo $GIT_PETCLIENTIC_SOURCE into your GitHub space and point the "
    echo "  the environment variable PCF_TILE_PBS_DEMO_PETCLINIC to it, so you can modify the content"
    echo ""
    variable_notice; exit 1
  fi
fi

if [ "${PCF_TILE_HARBOR_ADMIN_PASS}" == "" ]; then
  echo ""
  echo "  MISSING ENVIRONMENT-VARIABES  DESCRIPTION        "
  echo "  --------------------------------------------------------------------------------------------------------------"
  echo ""

  if [ "${PCF_TILE_HARBOR_ADMIN_PASS}" == "" ]; then
    echo "  PCF_TILE_HARBOR_ADMIN_PASS    (required) Harbor Administrator Password"
    echo ""
  fi

  variable_notice; exit 1
else
  messageTitle "  Pivotal Container Platform (Harbor)"
  messagePrint "   - Harbor Administrator Password" "##########"
  echo ""
fi

if [ "${PCF_TILE_PBS_ADMIN_USER}" == "" -o "${PCF_TILE_PBS_ADMIN_PASS}" == "" -o "${PCF_TILE_PBS_DOCKER_REPO}" == "" -o \
     "${PCF_TILE_PBS_DOCKER_USER}" == "" -o "${PCF_TILE_PBS_DOCKER_PASS}" == "" -o "${PCF_TILE_PBS_GITHUB_REPO}" == "" -o \
     "${PCF_TILE_PBS_GITHUB_USER}" == "" -o "${PCF_TILE_PBS_GITHUB_PASS}" == "" ]; then

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
  variable_notice; exit 1
else
  messageTitle "  Pivotal Container Platform (PBS)"
  messagePrint "   - PBS Administrator User"     "$PCF_TILE_PBS_ADMIN_USER"
  messagePrint "   - PBS Administrator Password" "##########"
  messagePrint "   - Docker Repository Name"     "$PCF_TILE_PBS_DOCKER_REPO"
  messagePrint "   - Docker Repository User"     "$PCF_TILE_PBS_DOCKER_USER"
  messagePrint "   - Docker Repository Password" "##########"
  messagePrint "   - GitHub Repository Name"     "$PCF_TILE_PBS_GITHUB_REPO"
  messagePrint "   - GitHub Repository User"     "$PCF_TILE_PBS_GITHUB_USER"
  messagePrint "   - GitHub Repository Password" "##########"
  echo ""
fi

HARBOR_REGISTRY="harbor.${PCF_DEPLOYMENT_ENV_NAME}.${AWS_HOSTED_DNS_DOMAIN}"
HARBOR_PROJECT=library
PCF_TILE_HARBOR_ADMIN_USER=admin

echo "registry: ${HARBOR_REGISTRY}"            >  /tmp/harbor.yml
echo "username: $PCF_TILE_HARBOR_ADMIN_USER"  >> /tmp/harbor.yml
echo "password: $PCF_TILE_HARBOR_ADMIN_PASS"  >> /tmp/harbor.yml

echo "registry: $PCF_TILE_PBS_GITHUB_REPO"    >  /tmp/github.yml
echo "username: $PCF_TILE_PBS_GITHUB_USER"    >> /tmp/github.yml
echo "password: $PCF_TILE_PBS_GITHUB_PASS"    >> /tmp/github.yml

export BUILD_SERVICE_USERNAME=$PCF_TILE_PBS_ADMIN_USER
export BUILD_SERVICE_PASSWORD=$PCF_TILE_PBS_ADMIN_PASS
PB_API_TARGET=https://build-service.apps-${PKS_CLNAME}.$PKS_ENNAME

prtHead "Set API Target for Pivotal Build Service (PBS)"
execCmd "pb api set ${PB_API_TARGET} --skip-ssl-validation"
execCmd "pb login"

prtHead "Create and select Project pet-clinic"
tgt=$(pb project target | egrep "Currently targeting" | sed -e "s/'//g" -e 's/\.//g'| awk '{ print $3 }')
if [ "${tgt}" != "pet-clinic-harbor" ]; then
  execCmd "pb project create pet-clinic-harbor"
fi
execCmd "pb project target pet-clinic-harbor"

prtHead "Add screts for Harbor Registry from (/tmp/harbor.yml)" 
execCmd "cat /tmp/harbor.yml | sed '/^password: /s/.*/password: xxxxxxxx/g'"
execCmd "pb secrets registry apply -f /tmp/harbor.yml"

prtHead "Add screts for Docker Registry from (/tmp/github.yml)" 
execCmd "cat /tmp/github.yml | sed '/^password: /s/.*/password: xxxxxxxx/g'"
execCmd "pb secrets registry apply -f /tmp/github.yml"

sed -e "s+XXXGITREPOSITORYXXX+${PCF_TILE_PBS_DEMO_PETCLINIC}+g" -e "s/XXXDOMAINXXX/${HARBOR_REGISTRY}/g" \
    -e "s/YYYREPOYYY/${HARBOR_PROJECT}/g" \
    files/spring-petclinic-harbor-template.yml > /tmp/spring-petclinic-harbor.yml

prtHead "Create Image (/tmp/spring-petclinic-harbor.yml)"
execCmd "cat /tmp/spring-petclinic-harbor.yml"
execCmd "pb image apply -f /tmp/spring-petclinic-harbor.yml"
sleep 7
execCmd "pb image list"
execCmd "pb image builds ${HARBOR_REGISTRY}/${HARBOR_PROJECT}/spring-petclinic:latest"

bld=$(pb image builds ${HARBOR_REGISTRY}/${HARBOR_PROJECT}/spring-petclinic:latest | \
      sed '/^$/d' | tail -1 | awk '{ print $1 }') 
execCmd "pb image logs ${HARBOR_REGISTRY}/${HARBOR_PROJECT}/spring-petclinic:latest -b $bld -f"

#prtText "Login in to Docker Repository on your local workstartion and run petclinic"
#prtText " => sudo docker login ${HARBOR_REGISTRY} -u $PCF_TILE_HARBOR_ADMIN_USER -p $PCF_TILE_HARBOR_ADMIN_PASS"
#prtText " => sudo docker run -e \"SPRING_PROFILES_ACTIVE=prod\" -p 8080:8080 -t --name springboot-petclinic ${PCF_TILE_PBS_DOCKER_REPO}/${PCF_TILE_PBS_DOCKER_USER}/spring-petclinic:latest"


exit


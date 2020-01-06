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

HARBOR_REGISTRY=https://demo.goharbor.io
HARBOR_REGISTRY=demo.goharbor.io

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

prtText " => sudo docker login ${HARBOR_REGISTRY} -u $PCF_PBS_GOHARBOR_USER -p $PCF_PBS_GOHARBOR_PASS"

PB=$(which pb)
if [ "$PB" == "" ]; then 
  echo "ERROR: The pb utility is not installed, please optain it from network.pivotal.io"
  exit
fi
missing_variables=0
if [ "${PCF_PBS_GOHARBOR_USER}" == "" -o "${PCF_PBS_GOHARBOR_PASS}" == "" -a "${PCF_PBS_GOHARBOR_PROJ}" == "" ]; then
  missing_variables=1
  echo ""
  echo "  MISSING ENVIRONMENT-VARIABES  DESCRIPTION        "
  echo "  --------------------------------------------------------------------------------------------------------------"

  if [ "${PCF_PBS_GOHARBOR_USER}" == "" ]; then
    echo "  PCF_TILE_HARBOR_ADMIN_USER    (required) Harbor Administrator User"
  fi

  if [ "${PCF_PBS_GOHARBOR_PASS}" == "" ]; then
    echo "  PCF_TILE_HARBOR_ADMIN_PASS    (required) Harbor Administrator Password"
  fi

  if [ "${PCF_PBS_GOHARBOR_PROJ}" == "" ]; then
    echo "  PCF_TILE_HARBOR_ADMIN_PROJ    (required) Harbor Project"
  fi

  echo ""
  echo "  A user account for the hosted harbor registry (https://$HARBOR_REGISTRY) can be optained under the"
  echo "  following link: https://github.com/goharbor/harbor/blob/master/docs/demo_server.md"
else
  messageTitle "Pivotal Container Platform (Harbor)"
  messagePrint " - Harbor Administrator User"     "$PCF_PBS_GOHARBOR_USER"
  messagePrint " - Harbor Administrator Password" "$PCF_PBS_GOHARBOR_PASS"
  echo ""
fi

if [ "${PCF_PBS_CFAPP_USER}" == "" -o "${PCF_PBS_CFAPP_PASS}" == "" -o "${PCF_TILE_PBS_DOCKER_REPO}" == "" -o \
     "${PCF_TILE_PBS_DOCKER_USER}" == "" -o "${PCF_TILE_PBS_DOCKER_PASS}" == "" -o "${PCF_TILE_PBS_GITHUB_REPO}" == "" -o \
     "${PCF_TILE_PBS_GITHUB_USER}" == "" -o "${PCF_TILE_PBS_GITHUB_PASS}" == "" ]; then
  missing_variables=1
  echo ""
  echo "  MISSING ENVIRONMENT-VARIABES  DESCRIPTION        "
  echo "  --------------------------------------------------------------------------------------------------------------"

  if [ "${PCF_PBS_CFAPP_USER}" == "" ]; then
    echo "  PCF_PBS_CFAPP_USER            (required) PBS Administrator User"
  fi

  if [ "${PCF_PBS_CFAPP_PASS}" == "" ]; then
    echo "  PCF_PBS_CFAPP_PASS            (required) PBS Administrator Password"
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
  messagePrint " - PBS Administrator User"     "$PCF_PBS_CFAPP_USER"
  messagePrint " - PBS Administrator Password" "$PCF_PBS_CFAPP_PASS"
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

echo "registry: $HARBOR_REGISTRY"             >  /tmp/harbor.yml
echo "username: $PCF_PBS_GOHARBOR_USER"       >> /tmp/harbor.yml
echo "password: $PCF_PBS_GOHARBOR_PASS"       >> /tmp/harbor.yml

echo "registry: $PCF_TILE_PBS_GITHUB_REPO"    >  /tmp/github.yml
echo "username: $PCF_TILE_PBS_GITHUB_USER"    >> /tmp/github.yml
echo "password: $PCF_TILE_PBS_GITHUB_PASS"    >> /tmp/github.yml

PB_LOGIN_REQUIRED=0
PB_API_TARGET=https://pbs.picorivera.cf-app.com
PB_API_CURRENT=$(pb api get 2>/dev/null | awk '{ print $NF }') 
[ "${PB_API_CURRENT}" != "${PB_API_TARGET}" ] && PB_LOGIN_REQUIRED=1

# --- CHECK IF LOGGED IN --
pb image list > /dev/null 2>&1
[ $? -ne 0 ] && PB_LOGIN_REQUIRED=1

prtHead "Set API Target for Pivotal Build Service (PBS)"
execCmd "pb api set $PB_API_TARGET --skip-ssl-validation"

if [ $PB_LOGIN_REQUIRED -eq 1 ]; then 
  prtHead "Login to the Pivotal Build Service as '$PCF_PBS_CFAPP_USER' and pawword '$PCF_PBS_CFAPP_PASS'"
  pb login
  echo ""
fi

prtHead "Create and select Project pet-clinic"
tgt=$(pb project target | egrep "Currently targeting" | sed -e "s/'//g" -e 's/\.//g'| awk '{ print $3 }')
if [ "${tgt}" != "pet-clinic-harbor" ]; then 
  execCmd "pb project create pet-clinic-harbor"
fi
execCmd "pb project target pet-clinic-harbor"

prtHead "Add screts for Harbor Registry from (/tmp/harbor.yml)" 
execCmd "cat /tmp/harbor.yml"
execCmd "pb secrets registry apply -f /tmp/harbor.yml"

prtHead "Add screts for Docker Registry from (/tmp/github.yml)" 
execCmd "cat /tmp/github.yml"
execCmd "pb secrets registry apply -f /tmp/github.yml"

sed -e "s/XXXDOMAINXXX/${HARBOR_REGISTRY}/g" -e "s/YYYREPOYYY/${PCF_PBS_GOHARBOR_PROJ}/g" \
    spring-petclinic-harbor-template.yml > spring-petclinic-harbor.yml

prtHead "Create Image (spring-petclinic-harbor.yml)"
execCmd "cat spring-petclinic-harbor.yml"
execCmd "pb image apply -f spring-petclinic-harbor.yml"
execCmd "pb image list"
sleep 10
execCmd "pb image logs ${HARBOR_REGISTRY}/sadubois/spring-petclinic:latest -b 1 -f"

prtText "Login in to Docker Repository on your local workstartion and run petclinic"
prtText " => sudo docker login ${HARBOR_REGISTRY} -u $PCF_PBS_GOHARBOR_USER -p $PCF_PBS_GOHARBOR_PASS"
prtText " => sudo docker run -e \"SPRING_PROFILES_ACTIVE=prod\" -p 8080:8080 -t --name springboot-petclinic ${PCF_TILE_PBS_DOCKER_REPO}/${PCF_TILE_PBS_DOCKER_USER}/spring-petclinic:latest"


exit


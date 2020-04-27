#!/bin/bash
# ============================================================================================
# File: ........: Clean_PetClinic_Hosted.sh
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

usage() {
  echo ""
  echo "Usage: $0 <DockerReg|goHarborReg>"
  echo "                                        |         |"
  echo "                                        |         |_____  Hosted Harbor Registry (demo.goharbor.io)"
  echo "                                        |_______________  Docker Hub Registry (index.docker.io)"
  echo ""
}

if [ "$#" -eq 0 ]; then
  usage; exit 0
fi

REGISTRY_DOCKER=0
REGISTRY_GOHARBOR=0

while [ "$1" != "" ]; do
  case $1 in
    DockerReg)    REGISTRY_DOCKER=1;;
    goHarborReg)  REGISTRY_GOHARBOR=1;;
  esac
  shift
done

if [ ${REGISTRY_DOCKER} -eq 0 -a ${REGISTRY_GOHARBOR} -eq 0 ]; then
  usage; exit
fi

PB=$(which pb)
if [ "$PB" == "" ]; then
  echo "ERROR: The pb utility is not installed, please optain it from network.pivotal.io"
  exit
fi

HARBOR_REGISTRY=https://demo.goharbor.io
HARBOR_REGISTRY=demo.goharbor.io
tocindex=""

missing_variables=0
if [ $REGISTRY_GOHARBOR -eq 1 ]; then
  CONTAINER_REGISTRY=demo.goharbor.io
  CONTAINER_PROJECT=$PCF_PBS_GOHARBOR_PROJ
  PBS_PROJECT=pet-clinic-goharbor

  if [ "${PCF_PBS_GOHARBOR_USER}" == "" -o "${PCF_PBS_GOHARBOR_PASS}" == "" -o "${PCF_PBS_GOHARBOR_PROJ}" == "" -o \
       "${PCF_PBS_GOHARBOR_EMAIL}" == "" -o "${PCF_PBS_GOHARBOR_FIRST_NAME}" == "" -o "${PCF_PBS_GOHARBOR_LAST_NAME}" == "" ]; then
    missing_variables=1
    echo "  MISSING ENVIRONMENT-VARIABES  DESCRIPTION        "
    echo "  --------------------------------------------------------------------------------------------------------------"

    if [ "${PCF_PBS_GOHARBOR_USER}" == "" ]; then
      echo "  PCF_PBS_GOHARBOR_USER         (required) goHarbor User Name"
    fi

    if [ "${PCF_PBS_GOHARBOR_PASS}" == "" ]; then
      echo "  PCF_PBS_GOHARBOR_PASS         (required) goHarbor User Password"
    fi

    if [ "${PCF_PBS_GOHARBOR_EMAIL}" == "" ]; then
      echo "  PCF_PBS_GOHARBOR_EMAIL        (required) goHarbor User Email"
    fi

    if [ "${PCF_PBS_GOHARBOR_FIRST_NAME}" == "" ]; then
      echo "  PCF_PBS_GOHARBOR_FIRST_NAME   (required) goHarbor User First Name"
    fi

    if [ "${PCF_PBS_GOHARBOR_LAST_NAME}" == "" ]; then
      echo "  PCF_PBS_GOHARBOR_LAST_NAME    (required) goHarbor User Last Name"
    fi

    if [ "${PCF_PBS_GOHARBOR_PROJ}" == "" ]; then
      echo "  PCF_TILE_HARBOR_ADMIN_PROJ    (required) goHarbor Project"
    fi

    echo ""
    echo "  A user account for the hosted harbor registry (https://$CONTAINER_REGISTRY) can be optained under the"
    echo "  following link: https://github.com/goharbor/harbor/blob/master/docs/demo_server.md"
    echo ""
  fi
fi

if [ $REGISTRY_DOCKER -eq 1 ]; then
  PBS_PROJECT=pet-clinic-docker
  CONTAINER_REGISTRY=$PCF_TILE_PBS_DOCKER_REPO
  CONTAINER_PROJECT=$PCF_TILE_PBS_DOCKER_USER

  if [ "${PCF_TILE_PBS_DOCKER_REPO}" == "" -o "${PCF_TILE_PBS_DOCKER_USER}" == "" -o "${PCF_TILE_PBS_DOCKER_PASS}" == "" ]; then
    echo "  MISSING ENVIRONMENT-VARIABES  DESCRIPTION        "
    echo "  --------------------------------------------------------------------------------------------------------------"
    echo ""

    if [ "${PCF_TILE_PBS_DOCKER_REPO}" == "" ]; then
      echo "  PCF_TILE_PBS_DOCKER_REPO      (required) Docker Registry"
    fi

    if [ "${PCF_TILE_PBS_DOCKER_USER}" == "" ]; then
      echo "  PCF_TILE_PBS_DOCKER_USER      (required) Harbor Administrator User"
      echo ""
    fi

    if [ "${PCF_TILE_HARBOR_ADMIN_PASS}" == "" ]; then
      echo "  PCF_TILE_HARBOR_ADMIN_PASS    (required) Harbor Administrator Password"
      echo ""
    fi

    variable_notice; exit 1
  fi
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
fi

export BUILD_SERVICE_USERNAME=$PCF_PBS_CFAPP_USER
export BUILD_SERVICE_PASSWORD=$PCF_PBS_CFAPP_PASS
PB_API_TARGET=https://pbs.picorivera.cf-app.com

#pb api set $PB_API_TARGET --skip-ssl-validation > /dev/null 2>&1
#pb login > /dev/null 2>&1
#if [ $? -ne 0 ]; then
#  echo "ERROR: Login to PBS service failed"
#  echo "       => pb api set $PB_API_TARGET --skip-ssl-validation"
#  echo "       => export BUILD_SERVICE_USERNAME=$PCF_PBS_CFAPP_USER"
#  echo "       => export BUILD_SERVICE_PASSWORD=$BUILD_SERVICE_PASSWORD"
#  echo "       => pb login"
#  exit
#fi

messageTitle "Cleaning up Pivotal Builds Service (PBS)" 
messageTitle "- Deleting project $PBS_PROJECT" 
messageTitle ""

for image in $(pb image list | sed '1,/^---/d'); do
  pb image delete $image
done

pb project delete $PBS_PROJECT 2>/dev/null




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

usage() {
  echo ""
  echo "Usage: $0 <HarborReg|DockerReg|goHarborReg>"
  echo "                                    |         |         |" 
  echo "                                    |         |         |_____  Hosted Harbor Registry (demo.goharbor.io)"
  echo "                                    |         |_______________  Docker Hub Registry (index.docker.io)"
  echo "                                    |_________________________  Harbor Registry on PKS"
  echo ""
}

if [ "$#" -eq 0 ]; then
  usage; exit 0
fi

REGISTRY_HARBOR=0
REGISTRY_DOCKER=0
REGISTRY_GOHARBOR=0

while [ "$1" != "" ]; do
  case $1 in
    HarborReg)    REGISTRY_HARBOR=1;;
    DockerReg)    REGISTRY_DOCKER=1;;
    goHarborReg)  REGISTRY_GOHARBOR=1;;
  esac
  shift
done

if [ ${REGISTRY_HARBOR} -eq 0 -a ${REGISTRY_DOCKER} -eq 0 -a ${REGISTRY_GOHARBOR} -eq 0 ]; then 
  usage; exit
fi

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
echo '              Demonstration for Pivotal Build Service (PBS) in a Hosted Environment   '
echo '                           by Sacha Dubois / Steve Schmidt, Pivotal Inc               '
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

PCF_TILE_HARBOR_ADMIN_USER=admin

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
  else
    if [ "${PCF_PBS_GOHARBOR_PROJ}" == "library" ]; then
      echo "ERROR: The goHarbor Registry does not allow 'library' as project"
      exit
    fi
  
    messageTitle "  Harbor Container Registry"
    messagePrint "   - Registry:"         "demo.goharbor.io"
    messagePrint "   - Project:"          "$PCF_PBS_GOHARBOR_PROJ"
    messagePrint "   - User Name:"        "$PCF_PBS_GOHARBOR_USER"
    messagePrint "   - User Password:"    "##########"
    messagePrint "   - User Email:"       "$PCF_PBS_GOHARBOR_EMAIL"
    messagePrint "   - User First Name:"  "$PCF_PBS_GOHARBOR_FIRST_NAME"
    messagePrint "   - User Last Name:"   "$PCF_PBS_GOHARBOR_LAST_NAME"
    messagePrint "   - Project Name:"     "$PCF_PBS_GOHARBOR_PROJ"
    echo ""

    harborAPIuserAdd demo.goharbor.io $PCF_PBS_GOHARBOR_USER $PCF_PBS_GOHARBOR_PASS \
                     $PCF_PBS_GOHARBOR_EMAIL $PCF_PBS_GOHARBOR_FIRST_NAME $PCF_PBS_GOHARBOR_LAST_NAME 

    harborAPIprojectAdd demo.goharbor.io $PCF_PBS_GOHARBOR_PROJ $PCF_PBS_GOHARBOR_USER $PCF_PBS_GOHARBOR_PASS

    #harborAPIuserUser demo.goharbor.io $PCF_PBS_GOHARBOR_USER $PCF_PBS_GOHARBOR_PASS \
    #                  $PCF_PBS_GOHARBOR_EMAIL $PCF_PBS_GOHARBOR_FIRST_NAME $PCF_PBS_GOHARBOR_LAST_NAME 
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
  else
    messageTitle "  Docker Container Registry"
    messagePrint "   - Registry URL:"          "$PCF_TILE_PBS_DOCKER_REPO"
    messagePrint "   - User"                   "$PCF_TILE_PBS_DOCKER_USER"
    messagePrint "   - Password"               "##########"
    echo ""
  fi
fi

if [ $REGISTRY_HARBOR -eq 1 ]; then 
  CONTAINER_REGISTRY="harbor.${PCF_DEPLOYMENT_ENV_NAME}.${AWS_HOSTED_DNS_DOMAIN}"
  CONTAINER_PROJECT=$PCF_PBS_HARBOR_PROJ
  PBS_PROJECT=pet-clinic-harbor

  if [ "${PCF_TILE_HARBOR_ADMIN_PASS}" == "" -o "${PCF_PBS_HARBOR_PROJ}" == "" ]; then
    echo "  MISSING ENVIRONMENT-VARIABES  DESCRIPTION        "
    echo "  --------------------------------------------------------------------------------------------------------------"
    echo ""

    if [ "${PCF_TILE_HARBOR_ADMIN_PASS}" == "" ]; then
      echo "  PCF_TILE_HARBOR_ADMIN_PASS    (required) Harbor Administrator Password"
      echo ""
    fi

    if [ "${PCF_PBS_HARBOR_PROJ}" == "" ]; then
      echo "  PCF_PBS_HARBOR_PROJ           (required) Harbor Project"
    fi
  
    variable_notice; exit 1
  else
    messageTitle "  Pivotal Container Platform (Harbor)"
    messagePrint "   - Harbor Registry:" "$CONTAINER_REGISTRY"
    messagePrint "   - Harbor Administrator User" "admin"
    messagePrint "   - Harbor Administrator Password" "##########"
    echo ""

    harborAPIprojectAdd $CONTAINER_REGISTRY $PCF_PBS_HARBOR_PROJ admin $PCF_TILE_HARBOR_ADMIN_PASS
  fi
fi

if [ "${PCF_TILE_PBS_ADMIN_USER}" == "" -o "${PCF_TILE_PBS_ADMIN_PASS}" == "" -o "${PCF_TILE_PBS_GITHUB_REPO}" == "" -o \
     "${PCF_TILE_PBS_GITHUB_USER}" == "" -o "${PCF_TILE_PBS_GITHUB_PASS}" == "" ]; then

  echo "  MISSING ENVIRONMENT-VARIABES  DESCRIPTION        "
  echo "  --------------------------------------------------------------------------------------------------------------"

  if [ "${PCF_TILE_PBS_ADMIN_USER}" == "" ]; then
    echo "  PCF_TILE_PBS_ADMIN_USER       (required) PBS Administrator User"
  fi

  if [ "${PCF_TILE_PBS_ADMIN_PASS}" == "" ]; then
    echo "  PCF_TILE_PBS_ADMIN_PASS       (required) PBS Administrator Password"
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
  messagePrint "   - GitHub Repository Name"     "$PCF_TILE_PBS_GITHUB_REPO"
  messagePrint "   - GitHub Repository User"     "$PCF_TILE_PBS_GITHUB_USER"
  messagePrint "   - GitHub Repository Password" "##########"
  echo ""
fi


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
execCmd "pb project create $PBS_PROJECT 2>/dev/null"
execCmd "pb project target $PBS_PROJECT"

if [ $REGISTRY_DOCKER -eq 1 ]; then 
  echo "registry: $PCF_TILE_PBS_DOCKER_REPO"    >  /tmp/docker.yml
  echo "username: $PCF_TILE_PBS_DOCKER_USER"    >> /tmp/docker.yml
  echo "password: $PCF_TILE_PBS_DOCKER_PASS"    >> /tmp/docker.yml

  prtHead "Add screts for Docker Registry from (/tmp/docker.yml)"
  execCmd "cat /tmp/docker.yml | sed '/^password: /s/.*/password: xxxxxxxx/g'"
  execCmd "pb secrets registry apply -f /tmp/docker.yml"

  sed -e "s+XXXGITREPOSITORYXXX+${PCF_TILE_PBS_DEMO_PETCLINIC}+g" -e "s/XXXDOMAINXXX/${CONTAINER_REGISTRY}/g" \
      -e "s/YYYREPOYYY/${CONTAINER_PROJECT}/g" \
      files/spring-petclinic-docker-template.yml > /tmp/spring-petclinic.yml
fi

if [ $REGISTRY_GOHARBOR -eq 1 ]; then 
  echo "registry: $CONTAINER_REGISTRY"             >  /tmp/harbor.yml
  echo "username: $PCF_PBS_GOHARBOR_USER"       >> /tmp/harbor.yml
  echo "password: $PCF_PBS_GOHARBOR_PASS"       >> /tmp/harbor.yml

  prtHead "Add secrets for Harbor Registry from (/tmp/harbor.yml)"
  execCmd "cat /tmp/harbor.yml | sed '/^password: /s/.*/password: xxxxxxxx/g'"
  execCmd "pb secrets registry apply -f /tmp/harbor.yml"

  sed -e "s+XXXGITREPOSITORYXXX+${PCF_TILE_PBS_DEMO_PETCLINIC}+g" -e "s/XXXDOMAINXXX/${CONTAINER_REGISTRY}/g" \
      -e "s/YYYREPOYYY/${CONTAINER_PROJECT}/g" \
      files/spring-petclinic-harbor-template.yml > /tmp/spring-petclinic.yml
fi

if [ $REGISTRY_HARBOR -eq 1 ]; then
  echo "registry: ${CONTAINER_REGISTRY}"           >  /tmp/harbor.yml
  echo "username: $PCF_TILE_HARBOR_ADMIN_USER"     >> /tmp/harbor.yml
  echo "password: $PCF_TILE_HARBOR_ADMIN_PASS"     >> /tmp/harbor.yml

  prtHead "Add secrets for Harbor Registry from (/tmp/harbor.yml)" 
  execCmd "cat /tmp/harbor.yml | sed '/^password: /s/.*/password: xxxxxxxx/g'"
  execCmd "pb secrets registry apply -f /tmp/harbor.yml"

  sed -e "s+XXXGITREPOSITORYXXX+${PCF_TILE_PBS_DEMO_PETCLINIC}+g" -e "s/XXXDOMAINXXX/${CONTAINER_REGISTRY}/g" \
      -e "s/YYYREPOYYY/${CONTAINER_PROJECT}/g" \
      files/spring-petclinic-harbor-template.yml > /tmp/spring-petclinic.yml
fi

prtHead "Add screts for Github Registry from (/tmp/github.yml)" 
execCmd "cat /tmp/github.yml | sed '/^password: /s/.*/password: xxxxxxxx/g'"
execCmd "pb secrets registry apply -f /tmp/github.yml"

prtHead "Create Image (/tmp/spring-petclinic.yml)"
execCmd "cat /tmp/spring-petclinic.yml"
execCmd "pb image apply -f /tmp/spring-petclinic.yml"
sleep 7
execCmd "pb image list"
execCmd "pb image builds ${CONTAINER_REGISTRY}/${CONTAINER_PROJECT}/spring-petclinic:latest"

bld=$(pb image builds ${CONTAINER_REGISTRY}/${CONTAINER_PROJECT}/spring-petclinic:latest | \
      sed '/^$/d' | tail -1 | awk '{ print $1 }') 
execCmd "pb image logs ${CONTAINER_REGISTRY}/${CONTAINER_PROJECT}/spring-petclinic:latest -b $bld -f"

if [ $REGISTRY_GOHARBOR -eq 1 ]; then
  prtText "Login in to Harbor Registry on ($CONTAINER_REGISTRY)"
  prtText " => https://$CONTAINER_REGISTRY"
fi

if [ $REGISTRY_HARBOR -eq 1 ]; then
  prtText "Login in to Harbor Registry on ($CONTAINER_REGISTRY)"
  prtText " => https://$CONTAINER_REGISTRY"
fi

if [ $REGISTRY_DOCKER -eq 1 ]; then
  prtText "Login in to Docker Registry on ($CONTAINER_REGISTRY)"
  prtText " => https://$PCF_TILE_PBS_DOCKER_REPO"
fi

prtText "Deploy the container to Docker/Kubernets"
prtText " => Deploy_PetClinic_K8s.sh"
prtText " => Deploy_PetClinic_Docker.sh"


#prtText "Login in to Docker Repository on your local workstartion and run petclinic"
#prtText " => sudo docker login ${CONTAINER_REGISTRY} -u $PCF_TILE_HARBOR_ADMIN_USER -p $PCF_TILE_HARBOR_ADMIN_PASS"
#prtText " => sudo docker run -e \"SPRING_PROFILES_ACTIVE=prod\" -p 8080:8080 -t --name springboot-petclinic ${PCF_TILE_PBS_DOCKER_REPO}/${PCF_TILE_PBS_DOCKER_USER}/spring-petclinic:latest"


exit


# ============================================================================================
# File: ........: deploy_demo_tls.sh
# Language .....: bash
# Author .......: Sacha Dubois, Pivotal
# --------------------------------------------------------------------------------------------
# Description ..: Monitoring with Grafana and Prometheus Demo
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
  echo "Usage: $0 <Registry> <Kubernetes>"
  echo ""
  echo "           Registry:   <HarborReg|DockerReg|goHarborReg>"
  echo "                           |         |         |"
  echo "                           |         |         |_____  Hosted Harbor Registry (demo.goharbor.io)"
  echo "                           |         |_______________  Docker Hub Registry (index.docker.io)"
  echo "                           |_________________________  Harbor Registry on PKS"
  echo ""
  echo "           Kubernetes: <PKS|AKS|GKE|EKS|Minikube>"
  echo "                         |   |   |   |     |"
  echo "                         |   |   |   |     |_________  Minukube on Local Host"
  echo "                         |   |   |   |_______________  Amazon EKS - Managed Kubernetes Service"
  echo "                         |   |   |___________________  Google Kubernetes Engine (GKE)"
  echo "                         |   |_______________________  Azure Kubernetes Service (AKS)"
  echo "                         |___________________________  Pivotal Container Service (PKS)"
  echo ""
}

REGISTRY_HARBOR=0
REGISTRY_DOCKER=0
REGISTRY_GOHARBOR=0
KUBERNETES_PKS=0
KUBERNETES_AKS=0
KUBERNETES_EKS=0
KUBERNETES_GKE=0
KUBERNETES_MINIKUBE=0

while [ "$1" != "" ]; do
  case $1 in
    HarborReg)    REGISTRY_HARBOR=1;;
    DockerReg)    REGISTRY_DOCKER=1;;
    goHarborReg)  REGISTRY_GOHARBOR=1;;
    PKS)          KUBERNETES_PKS=1;;
    AKS)          KUBERNETES_AKS=1;;
    EKS)          KUBERNETES_EKS=1;;
    GKE)          KUBERNETES_GKE=1;;
    Minikube)     KUBERNETES_MINIKUBE=1;;
  esac
  shift
done

if [ ${REGISTRY_HARBOR} -eq 0 -a ${REGISTRY_DOCKER} -eq 0 -a ${REGISTRY_GOHARBOR} -eq 0 ]; then
  usage; exit
fi

if [ ${REGISTRY_HARBOR} -eq 0 -a ${REGISTRY_DOCKER} -eq 0 -a ${REGISTRY_GOHARBOR} -eq 0 ]; then
  usage; exit
fi

if [ ${KUBERNETES_PKS} -eq 0 -a ${KUBERNETES_AKS} -eq 0 -a ${KUBERNETES_EKS} -eq 0 -a ${KUBERNETES_GKE} -eq 0 -a \
     ${KUBERNETES_MINIKUBE} -eq 0 ]; then
  usage; exit
fi

# Created by /usr/local/bin/figlet
clear
echo '                                                                                      '
echo '           ____             _               ____      _      ____ _ _       _         '
echo '          / ___| _ __  _ __(_)_ __   __ _  |  _ \ ___| |_   / ___| (_)_ __ (_) ___    '
echo '          \___ \|  _ \|  __| |  _ \ / _  | | |_) / _ \ __| | |   | | |  _ \| |/ __|   '
echo '           ___) | |_) | |  | | | | | (_| | |  __/  __/ |_  | |___| | | | | | | (__    '
echo '          |____/| .__/|_|  |_|_| |_|\__, | |_|   \___|\__|  \____|_|_|_| |_|_|\___|   '
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

if [ $KUBERNETES_PKS -eq 1 -o $REGISTRY_HARBOR -eq 1 ]; then
  if [ -f /tmp/deployPCFenv_${PKS_ENNAME} ]; then
    . /tmp/deployPCFenv_${PKS_ENNAME}
  fi

  showK8sEnvironment

  pks get-credentials cl1 > /dev/null 2>&1
fi

if [ $KUBERNETES_MINIKUBE -eq 1 ]; then
  minikube status > /dev/null 2>&1; ret=$?
  if [ $ret -ne 0 ]; then 
    echo "ERROR: Minikube does not seams to run, please start it"
    exit 1
  fi

  minikube addons enable ingress /dev/null 2>&1

  profile=$(minikube profile) 
  kubectl config set-context minikube > /dev/null
fi

missing_variables=0
GIT_PETCLIENTIC_SOURCE=https://github.com/spring-projects/spring-petclinic
if [ $REGISTRY_GOHARBOR -eq 1 ]; then
  CONTAINER_REGISTRY=demo.goharbor.io
  CONTAINER_PROJECT=$PCF_PBS_GOHARBOR_PROJ

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

  # --- GENERATE INGRES FILES ---
  cat files/spring-petclinic-ingress-template.yml | sed -e "s/DOMAIN/info/g" > /tmp/spring-petclinic-ingress.yml
fi

if [ $REGISTRY_DOCKER -eq 1 ]; then
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

  # --- GENERATE INGRES FILES ---
  cat files/spring-petclinic-ingress-template.yml | sed -e "s/DOMAIN/info/g" > /tmp/spring-petclinic-ingress.yml
fi

if [ $REGISTRY_HARBOR -eq 1 ]; then
  CONTAINER_REGISTRY="harbor.${PCF_DEPLOYMENT_ENV_NAME}.${AWS_HOSTED_DNS_DOMAIN}"
  CONTAINER_PROJECT=$PCF_PBS_HARBOR_PROJ

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

  # --- LOAD CLOUD ENVIRONMENT ---
  dom=$(pks cluster cl1 | grep "Kubernetes Master Host" | awk '{ print $NF }' | sed 's/cl1\.//g')
  dom="${PCF_DEPLOYMENT_ENV_NAME}.${AWS_HOSTED_DNS_DOMAIN}"
  
  if [ -f ../../certificates/$dom/fullchain.pem ]; then
    TLS_CERTIFICATE=../../certificates/$dom/fullchain.pem
    TLS_PRIVATE_KEY=../../certificates/$dom/privkey.pem
  fi

  if [ -f ../../certificates/fullchain.pem ]; then
    TLS_CERTIFICATE=../../certificates/fullchain.pem
    TLS_PRIVATE_KEY=../../certificates/privkey.pem
  fi

  # --- CHECK IF CERTIFICATE HAS BEEN DEFINED ---
  if [ "${TLS_CERTIFICATE}" == "" -o "${TLS_PRIVATE_KEY}" == "" ]; then
    echo ""
    echo "ERROR: Certificate and Private-Key has not been specified. Please set"
    echo "       the following environment variables:"
    echo "       => export TLS_CERTIFICATE=<cert.pem>"
    echo "       => export TLS_PRIVATE_KEY=<private_key.pem>"
    echo ""
    exit 1
  else
    verifyTLScertificate $TLS_CERTIFICATE $TLS_PRIVATE_KEY
  fi

  # --- CONVERT CERTS TO BASE64 ---
  cert=$(base64 $TLS_CERTIFICATE)
  pkey=$(base64 $TLS_PRIVATE_KEY)

  # --- GENERATE INGRES FILES ---
  cat files/spring-petclinic-ingress-template_tls.yml | sed -e "s/DOMAIN/$PKS_APPATH/g" > /tmp/spring-petclinic-ingress.yml
  echo " tls.crt: \"$cert\"" >> /tmp/spring-petclinic-ingress.yml
  echo " tls.key: \"$pkey\"" >> /tmp/spring-petclinic-ingress.yml
fi


 
NAMESPACE=spring-petclinic
PETCLINIC_IMAGE=${CONTAINER_REGISTRY}/${CONTAINER_PROJECT}/spring-petclinic:latest

echo "PETCLINIC_IMAGE:$PETCLINIC_IMAGE"

kubectl get namespace $NAMESPACE > /dev/null 2>&1
if [ $? -eq 0 ]; then
  echo "ERROR: Namespace '$NAMESPACE' already exist"
  echo "       => kubectl delete namespace $NAMESPACE"
  exit 1
fi

prtHead "Create seperate namespace to host the Spring Petclinic Demo"
execCmd "kubectl create namespace $NAMESPACE"

prtHead "Create the deployment for stilton-cheese"
execCmd "kubectl create deployment spring-petclinic --image=$PETCLINIC_IMAGE -n $NAMESPACE"

#kubectl run spring-petclinic --image=harbor.gcppks.pcfsdu.com/library/spring-petclinic:latest --port=443

prtHead "Verify Deployment for stilton and cheddar cheese"
execCmd "kubectl get deployment,pods -n $NAMESPACE"

prtHead "Create service type NodePort on port 80 for both deployments"
execCmd "kubectl expose deployment spring-petclinic --type=NodePort --port=8080 -n $NAMESPACE"

prtHead "Verify services of cheddar-cheese and stilton-cheese"
execCmd "kubectl get svc -n $NAMESPACE"

prtHead "Describe services cheddar-cheese and stilton-cheese"
execCmd "kubectl describe svc spring-petclinic -n $NAMESPACE"

prtHead "Review ingress configuration file (/tmp/spring-petclinic-ingress.yml)"
execCmd "more /tmp/spring-petclinic-ingress.yml"

prtHead "Create ingress routing cheddar-cheese and stilton-cheese service"
execCmd "kubectl create -f /tmp/spring-petclinic-ingress.yml -n $NAMESPACE"
execCmd "kubectl get ingress -n $NAMESPACE"
execCmd "kubectl describe ingress -n $NAMESPACE"

prtHead "Open WebBrowser and verify the deployment"
echo "     => https://spring-petclinic.$PKS_APPATH"
echo ""

exit 0

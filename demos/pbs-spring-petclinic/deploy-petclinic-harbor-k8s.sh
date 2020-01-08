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

showK8sEnvironment

# --- LOAD CLOUD ENVIRONMENT ---
dom=$(pks cluster cl1 | grep "Kubernetes Master Host" | awk '{ print $NF }' | sed 's/cl1\.//g')

if [ -d ../../certificates/$dom -a "$dom" != "" ]; then 
  TLS_CERTIFICATE=../../certificates/$dom/fullchain.pem 
  TLS_PRIVATE_KEY=../../certificates/$dom/privkey.pem 
fi

pks get-credentials cl1 > /dev/null 2>&1
uid=$(kubectl config view -o jsonpath="{.contexts[?(@.name == \"cl1\")].context.user}")
tok=$(kubectl describe secret $(kubectl get secret | grep $uid | awk '{print $1}') | grep "token:" | awk '{ print $2 }')

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

NAMESPACE=spring-petclinic
PETCLINIC_REPO=harbor.$dom
PETCLINIC_IMAGE=${PETCLINIC_REPO}/library/spring-petclinic:latest

echo "PETCLINIC_REPO:$PETCLINIC_REPO"
echo "PETCLINIC_IMAGE:$PETCLINIC_IMAGE"

kubectl get namespace $NAMESPACE > /dev/null 2>&1
if [ $? -eq 0 ]; then
  echo "ERROR: Namespace '$NAMESPACE' already exist"
  echo "       => kubectl delete namespace $NAMESPACE"
  exit 1
fi

# --- CONVERT CERTS TO BASE64 ---
cert=$(base64 $TLS_CERTIFICATE) 
pkey=$(base64 $TLS_PRIVATE_KEY) 

# --- GENERATE INGRES FILES ---
cat files/spring-petclinic-ingress-template.yml | sed -e "s/DOMAIN/$PKS_APPATH/g" > /tmp/spring-petclinic-ingress_tls.yml
echo " tls.crt: \"$cert\"" >> /tmp/spring-petclinic-ingress_tls.yml
echo " tls.key: \"$pkey\"" >> /tmp/spring-petclinic-ingress_tls.yml

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

prtHead "Review ingress configuration file (/tmp/spring-petclinic-ingress_tls.yml)"
execCmd "more /tmp/spring-petclinic-ingress_tls.yml"

prtHead "Create ingress routing cheddar-cheese and stilton-cheese service"
execCmd "kubectl create -f /tmp/spring-petclinic-ingress_tls.yml -n $NAMESPACE"
execCmd "kubectl get ingress -n $NAMESPACE"
execCmd "kubectl describe ingress -n $NAMESPACE"

prtHead "Open WebBrowser and verify the deployment"
echo "     => https://spring-petclinic.$PKS_APPATH"
echo ""

exit 0

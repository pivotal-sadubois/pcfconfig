#!/bin/bash
# ============================================================================================
# File: ........: deploy_demo.sh
# Language .....: bash
# Author .......: Sacha Dubois, Pivotal
# --------------------------------------------------------------------------------------------
# Description ..: Demonstration for Ingress Routing based on two different URL
# ============================================================================================

BASENAME=$(basename $0)
DIRNAME=$(dirname $0)

if [ -f ${DIRNAME}/../../functions ]; then 
  . ${DIRNAME}/../../functions
else
  echo "ERROR: can ont find ${DIRNAME}/../../functions"; exit 1
fi

# --- LOAD CLOUD ENVIRONMENT ---
dom=$(pks cluster cl1 | grep "Kubernetes Master Host" | awk '{ print $NF }' | sed 's/cl1\.//g')

kubectl get namespace cheese > /dev/null 2>&1
if [ $? -eq 0 ]; then 
  echo "ERROR: Namespace 'cheese' already exist"
  echo "       => kubectl delete namespace cheese"
  exit 1
fi

# Created by /usr/local/bin/figlet
clear
echo '                                                                                      '
echo '              ___                                   ____ _                            '
echo '             |_ _|_ __   __ _ _ __ ___  ___ ___    / ___| |__   ___  ___  ___  ___    '
echo '              | ||  _ \ / _  |  __/ _ \/ __/ __|  | |   |  _ \ / _ \/ _ \/ __|/ _ \   '
echo '              | || | | | (_| | | |  __/\__ \__ \  | |___| | | |  __/  __/\__ \  __/   '
echo '             |___|_| |_|\__, |_|  \___||___/___/   \____|_| |_|\___|\___||___/\___|   '
echo '                        |___/                                                         '
echo '                                   ____                                               '
echo '                                  |  _ \  ___ _ __ ___   ___                          '
echo '                                  | | | |/ _ \  _   _ \ / _ \                         '
echo '                                  | |_| |  __/ | | | | | (_) |                        '
echo '                                  |____/ \___|_| |_| |_|\___/                         '
echo '                                                                                      '
echo '          ----------------------------------------------------------------------------'
echo '                   Demonstration for Ingress Routing based on two different URL       '
echo '                                    by Sacha Dubois, Pivotal Inc                      '
echo '          ----------------------------------------------------------------------------'
echo '                                                                                      '

showK8sEnvironment

# GENERATE INGRES FILES
cat ${DIRNAME}/template_cheese-ingress.yml | sed "s/DOMAIN/$PKS_APPATH/g" > /tmp/cheese-ingress.yml

prtHead " 1.) Create seperate namespace to host the Ingress Cheese Demo"
execCmd "kubectl create namespace cheese" 

prtHead " 2.) Create the deployment for stilton-cheese"
execCmd "kubectl create deployment stilton-cheese --image=errm/cheese:stilton -n cheese"

prtHead " 3.) Create the deployment for stilton-cheese"
execCmd "kubectl create deployment cheddar-cheese --image=errm/cheese:cheddar -n cheese"

prtHead " 4.) Verify Deployment for stilton and cheddar cheese"
execCmd "kubectl get deployment,pods -n cheese"

prtHead " 5.) Create service type NodePort on port 80 for both deployments"
execCmd "kubectl expose deployment stilton-cheese --type=NodePort --port=80 -n cheese"

prtHead " 6.) Create service type NodePort on port 80 for both deployments"
execCmd "kubectl expose deployment cheddar-cheese --type=NodePort --port=80 -n cheese"

prtHead " 7.) Verify services of cheddar-cheese and stilton-cheese"
execCmd "kubectl get svc -n cheese"

prtHead " 8.) Describe services cheddar-cheese and stilton-cheese"
execCmd "kubectl describe svc cheddar-cheese -n cheese"
execCmd "kubectl describe svc stilton-cheese -n cheese"

prtHead " 9.) Review ingress configuration file (/tmp/cheese-ingress.yml)"
execCmd "more /tmp/cheese-ingress.yml"

prtHead "10.) Create ingress routing cheddar-cheese and stilton-cheese service"
execCmd "kubectl create -f /tmp/cheese-ingress.yml -n cheese"
execCmd "kubectl get ingress -n cheese"
execCmd "kubectl describe ingress -n cheese"

prtHead "10.) Open WebBrowser and verify the deployment"
prtText "     => http://cheddar-cheese.apps-cl1.$dom"
prtText "     => http://stilton-cheese.apps-cl1.$dom"
prtText ""

exit 0

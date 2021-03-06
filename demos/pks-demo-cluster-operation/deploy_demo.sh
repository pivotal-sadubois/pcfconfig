#!/bin/bash
# ============================================================================================
# File: ........: deploy_demo.sh
# Language .....: bash
# Author .......: Sacha Dubois, Pivotal
# --------------------------------------------------------------------------------------------
# Description ..: Kubernetes Cluster Monitoring with Grafana and Prometheus
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
echo '                                                                                      '
echo '                       ____  _  ______       _       _           _                    '
echo '                      |  _ \| |/ / ___|     / \   __| |_ __ ___ (_)_ __               '
echo '                      | |_) |   /\___ \    / _ \ / _  |  _   _ \| |  _ \              '
echo '                      |  __/|   \ ___) |  / ___ \ (_| | | | | | | | | | |             '
echo '                      |_|   |_|\_\____/  /_/   \_\__,_|_| |_| |_|_|_| |_|             '
echo '                                                                                      '
echo '          ----------------------------------------------------------------------------'
echo '                   Kubernetes Cluster Monitoring with Grafana and Prometheus          '
echo '                                  by Sacha Dubois, Pivotal Inc                        '
echo '          ----------------------------------------------------------------------------'
echo '                                                                                      '

showK8sEnvironment

userid=sadubois
api=$(pks cluster cl1 | grep "Kubernetes Master Host" | awk '{ print $NF }' | sed 's/cl1/api.pks/g') 

prtHead "Login into PKS environment"
execCmd "pks login -u sadubois -p pivotal -a $api --skip-ssl-validation"

pks get-credentials cl1 > /dev/null 2>&1
uid=$(kubectl config view -o jsonpath="{.contexts[?(@.name == \"cl1\")].context.user}")
tok=$(kubectl describe secret $(kubectl get secret | grep $uid | awk '{print $1}') | grep "token:" | awk '{ print $2 }')

# --- START KUBCTL PROXY ---
kubectl proxy > /dev/null 2>&1 &

prtHead "To start Kubernetes Dashboard"
prtText "-----------------------------------------------------------------------------------------------------------"
prtText "=> kubectl proxy"
prtText "=> WebURL.: http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/"
prtText "=> Token..: $tok"
prtText "-----------------------------------------------------------------------------------------------------------"; read x

prtHead "Show PKS Clusters"
execCmd "pks clusters"

prtHead "Show details of PKS Cluster cl1"
execCmd "pks cluster cl1"

prtHead "Resize the Cluster (cl1)"
execCmd "pks resize cl1 --num-nodes 4 --non-interactive"

prtHead "Show details of PKS Cluster cl1"
execCmd "pks cluster cl1"

prtHead "Show available plans for PKS Clusters"
execCmd "pks plans"

prtHead "Create Cluster (cl2)"
execCmd "pks create-cluster cl2 --plan small --external-hostname cl1.awspks.pcfsdu.com"

prtHead "Show PKS Clusters"
execCmd "pks clusters"

prtHead "Show details of PKS Cluster cl2"
execCmd "pks cluster cl2"


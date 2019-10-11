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

#kubectl get namespace monitoring > /dev/null 2>&1
#if [ $? -eq 0 ]; then 
#  echo "ERROR: Namespace 'monitoring' already exist"
#  echo "       => kubectl delete namespace monitoring"
#  exit 1
#fi

# Created by /usr/local/bin/figlet
clear
echo '                                                                                      '
echo '                     __  __             _ _             _                             '
echo '                    |  \/  | ___  _ __ (_) |_ ___  _ __(_)_ __   __ _                 '
echo '                    | |\/| |/ _ \|  _ \| | __/ _ \|  __| |  _ \ / _  |                '
echo '                    | |  | | (_) | | | | | || (_) | |  | | | | | (_| |                '
echo '                    |_|  |_|\___/|_| |_|_|\__\___/|_|  |_|_| |_|\__, |                '
echo '                                                                 |___/                '
echo '                                 ____                                                 '
echo '                                |  _ \  ___ _ __ ___   ___                            '
echo '                                | | | |/ _ \  _   _ \ / _ \                           '
echo '                                | |_| |  __/ | | | | | (_) |                          '
echo '                                |____/ \___|_| |_| |_|\___/                           '
echo '                                                                                      '
echo '          ----------------------------------------------------------------------------'
echo '                   Kubernetes Cluster Monitoring with Grafana and Prometheus          '
echo '                                  by Sacha Dubois, Pivotal Inc                        '
echo '          ----------------------------------------------------------------------------'
echo '                                                                                      '

showK8sEnvironment

# GENERATE INGRES FILES
cat ${DIRNAME}/template_grafana_ingress.yml | sed "s/DOMAIN/$PKS_APPATH/g" > /tmp/grafana_ingress.yml

prtHead "Create seperate namespace to host the Monitoring Demo"
execCmd "kubectl create namespace monitoring" 

prtHead "Apply the prometheus RBAC policy spec"
execCmd "kubectl apply -f prometheus-rbac.yaml -n monitoring"

prtHead "Apply the prometheus config-map spec"
execCmd "kubectl apply -f prometheus-config-map.yaml -n monitoring"

prtHead "Deploy the Prometheus application spec and verify all pods transitioning to Running"
execCmd "kubectl apply -f prometheus-deployment.yaml -n monitoring"
execCmd "kubectl wait --for=condition=ready pod -l app=prometheus-server --timeout=60s -n monitoring"
execCmd "kubectl get pods -n monitoring"

prtHead "Install the grafana Helm chart"
execCmd "helm install --name grafana ./grafana --namespace monitoring > /dev/null 2>&1"

prtHead "Review ingress configuration file (/tmp/grafana_ingress.yml)"
execCmd "more /tmp/grafana_ingress.yml"

prtHead "Create ingress routing for the grafana service"
execCmd "kubectl create -f /tmp/grafana_ingress.yml -n monitoring"
execCmd "kubectl get ingress -n monitoring"
execCmd "kubectl describe ingress -n monitoring"

prtHead "Collect and record the secret"
execCmd "kubectl get secret --namespace monitoring grafana -o jsonpath='{.data.admin-password}' | /usr/bin/base64 --decode; echo"

prtHead "Open WebBrowser and verify the deployment"
prtText "  => http://grafana.apps-${PKS_CLNAME}.${PKS_ENNAME}"; read x

prtHead "Configure the prometheus plug-in"
prtText "  => Select > Add data source"
prtText "  => Select > Prometheus"
prtText "  => URL: http://prometheus.monitoring.svc.cluster.local:9090"
prtText "  => Select > Save and Test"; read x

prtHead "Import the Kubernetes Dashboard"
prtText "  => Select > '+' in left pane then 'Import'"
prtText "  => Enter ID: 1621"
prtText "  => Select: Prometheus"; read x



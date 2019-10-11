# kubernetes-monitoring
# https://github.com/csaroka/kubernetes-monitoring
# https://github.com/csaroka/kubernetes-monitoring.git

## Deploy Prometheus

#### Create a namespace 
`$ kubectl create namespace monitoring`
#### Switch position to namespace monitoring
`$ kubectl config set-context $(kubectl config current-context) --namespace=monitoring`
#### Apply the prometheus RBAC policy spec
`$ kubectl apply -f prometheus-rbac.yaml`
#### Apply the prometheus config-map spec
`$ kubectl apply -f prometheus-config-map.yaml`

****Note: Before running the next command, open prometheus-deployment.yaml with vi or another editor and update image location; the default is the public image location: `prom/prometheus`

#### Deploy the Prometheus application spec and verify all pods transitioning to “Running
`$ kubectl apply  -f prometheus-deployment.yaml`\
`$ kubectl get pods`

## Deploy Grafana
#### Install helm client 
Go to: https://docs.helm.sh/using_helm/#installing-helm or \
`$ curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get > get_helm.sh`\
`$ chmod 700 get_helm.sh`\
`$ ./get_helm.sh`\
#### Apply the tiller RBAC policy 
`$ kubectl apply -f tiller-rbac.yaml`
#### Initilize tiller on the Kubernetes cluster
`$ helm init --service-account tiller`

****Note: Before running the next command, open grafana/values.yaml with vi or another editor and update image location and tag; the default is the public image location: `grafana/grafana`

#### Install the grafana Helm chart
`$ helm install --name grafana ./grafana`

#### Collect and record the secret
`$ kubectl get secret --namespace monitoring grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo`\

#### Collect the *EXTERNAL-IP* for the grafana service
`$ kubectl get svc |grep grafana`

#### Open a web browser, navigate to the grafana web UI, and login
http://GRAFANA_SERVICE_EXTERNAL-IP

*User Name:* admin

*Pasword:* <Output from Above>

#### Configure the prometheus plug-in 
Select > *Add data source*

Name: *Prometheus*

Type: *Prometheus*

URL: hhttp://prometheus.monitoring.svc.cluster.local:9090

Select > *Save and Test*

#### Import the Kubernetes Dashboard

Select > *"+"* in left pane then *"Import"*

If the app has Internet Access, enter ID **1621** then click outside of the field; otherwise, import the .json file located in the repo.

If no Internet Access, you can upload the .json file. 

In the Options table, select the Prometheus drop-down and select Prometheus 
Select > *Import* 

You will redirect to the new dashboard. 


# GET CL£USTER ADMIN 
kubectl create clusterrolebinding add-on-cluster-admin --clusterrole=cluster-admin --serviceaccount=kube-system:default 


helm init --history-max 200
helm repo update
kubectl apply -f 
helm init --service-account tiller
#helm install --name demo ./k8s/demo
helm list

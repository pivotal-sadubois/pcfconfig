#!/bin/bash
if [ "$1" == "" ]; then
  echo "USAGE: $0 <env> <region>"
  echo "       $0 gcppks europe-west4"  
  exit 0
fi

ENV_NAME="$1"
GCP_REGION=$2
SERVICE_ACCOUNT=pcfconfig
GCP_PROJECT=pa-sadubois

. ../functions

cleanGCPenv

exit

ENV=gcppas

#gcloud compute health-checks list
#gcloud compute target-tcp-proxies list
#gcloud compute target-http-proxies list
#gcloud compute forwarding-rules 
#gcloud compute addresses list

for n in $(gcloud compute target-http-proxies list 2>/dev/null | egrep "^${ENV}-" | awk '{ print $1 }'); do
  echo "=> Deleting target-http-proxies $n"
  gcloud compute target-http-proxies delete $n -q 
done

for n in $(gcloud compute url-maps list 2>/dev/null| egrep "^${ENV}-" | awk '{ print $1 }'); do
  echo "=> Deleting uri-maps $n"
  gcloud compute url-maps delete $n -q 
done

for n in $(gcloud compute backend-services list 2>/dev/null| egrep "^${ENV}-" | awk '{ print $1 }'); do
  echo "=> Deleting backend-service $n"
  gcloud compute backend-services delete $n -q --global
done

# IMAGES
for n in $(gcloud compute images list 2>/dev/null| egrep "^${ENV}-" | awk '{ print $1 }'); do
  echo "=> Deleting Image $n"
  gcloud compute images delete $n -q
done

for n in $(gcloud dns managed-zones list 2>/dev/null| egrep "^${ENV}-" | awk '{ print $1 }'); do 
  echo "=> Deleting Zone $n"
  gcloud dns record-sets import -z $n  --delete-all-existing /dev/null
  gcloud dns managed-zones delete $n
done

for n in $(gcloud compute instance-groups list | egrep "^$ENV-" | awk '{ printf("%s:%s:%s\n",$1,$2,$4 )}'); do
  nm=$(echo $n | awk -F: '{ print $1 }')
  zn=$(echo $n | awk -F: '{ print $2 }')
  mg=$(echo $n | awk -F: '{ print $3 }')
  
  if [ "$mg" == "No" ]; then 
    gcloud compute instance-groups unmanaged delete $nm --zone $zn -q
  else
    gcloud compute instance-groups managed delete $nm --zone $zn -q
  fi
done

for n in $(gcloud iam service-accounts list 2>/dev/null| awk '{ print $(NF-1) }' | grep $ENV); do
  echo "=> Deleting Service Account $n"
  gcloud iam service-accounts delete $n -q
done


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


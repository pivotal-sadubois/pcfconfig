#!/bin/bash
if [ "$1" == "" ]; then
  echo "USAGE: $0 <env> <region>"
  echo "       $0 awspks eu-central-1"
  exit 0
fi

ENV_NAME="$1"
AWS_LOCATION=$2

. ../functions

cleanAWSenv

exit


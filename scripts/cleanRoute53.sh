#!/bin/bash
if [ "$1" == "" ]; then
  echo "USAGE: $0 <env> <region> <dns-domain> <route53-token>"
  echo "       $0 awspks eu-central-1 pcfsdu.com Z1X9T7571BMHB5"
  exit 0
fi

ENV_NAME="$1"
AWS_LOCATION=$2
DNS_SUFFIX=pcfsdu.com
ROUTE53_TOKEN=Z1X9T7571BMHB5

. ../functions

cleanRoute53

exit


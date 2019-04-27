#!/bin/bash
# ########################################################################
# File: ........: pcfconfig.#h
# Language .....: bash
# Author .......: Sacha Dubois, Pivotal
# Description ..: PCF OpsManager Configuration Utility
# ########################################################################

if [ "$1" == "" -o $# -ne 2 ]; then
  echo "USAGE: $0 <terraform.tfvars> <terraform.tfstate>"; exit 0
fi

JQ=$(which jq)
if [ "${JQ}" == "" ]; then
  echo "ERROR: please install the jq utility from https://stedolan.github.io/jq/download"; exit 0
fi

# --- TEST FOR WORKING JQ UTILITY ---
if [ "$(JQ -V | egrep -c '^jq-')" -eq 1 -a "$(echo '{"foo": 42}' | jq .foo)" != "42" ]; then
  echo "ERROR: "
fi

TERRAFORM_VARS=$1
TERRAFORM_TFSTATES=$2
VARFILE=./vars

# --- CHECK FOR A TERRAFORM JSON FILE --
ver=`jq -r '.terraform_version' $TERRAFORM_TFSTATES 2>/dev/null`
if [ "${ver}" == "" ]; then
  echo "ERROR: $0 $TERRAFORM_TFSTATES is not a terraform state file"; exit 1
fi

#jq -rM -f jq-filter awa-pks-terraform.tfstate
jq -e -f jq-filter awa-pks-terraform.tfstate | sed -e 's/^"//g' -e 's/"$//g' -e 's/<1>/"/g'

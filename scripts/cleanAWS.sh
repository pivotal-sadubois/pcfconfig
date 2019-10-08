#!/bin/bash
# ############################################################################################
# File: ........: cleanAWS.sh
# Language .....: bash
# Author .......: Sacha Dubois, Pivotal
# Cathegory ....: PCF Installation and Configuration Utility
# Description ..: Clean AWS Environment 
# ############################################################################################

# --- CHECK ENVIRONMENT VARIABLES ---
if [ -f ~/.pcfconfig ]; then
  . ~/.pcfconfig
fi

if [ "$1" == "" ]; then
  echo "USAGE: $0 <env> <region>"
  echo "       $0 awspks eu-central-1"
  exit 0
fi

if [ "$AWS_HOSTED_DNS_DOMAIN" == "" ]; then
  echo "ERROR: DNS Domain not specified."
  echo "       => export AWS_HOSTED_DNS_DOMAIN=<domain>"
  exit 0
fi

ENV_NAME="$1"
AWS_LOCATION=$2

. ../functions

cleanAWSenv

exit


#!/bin/bash

##############################################################################################
############################### COMMAND-LINE ARGS PROCESSING  ################################
##############################################################################################

while [ "$1" != "" ]; do
  case $1 in
    --no-ask) NOASK=1;;
    --deployment) TF_DEPLOYMENT=$2; shift;;         # TERRAFORM VARIABLE FILE
    --aws-route53) ROUTE53_TOKEN=$2; shift;;        # TERRAFORM VARIABLE FILE
  esac
  shift
done




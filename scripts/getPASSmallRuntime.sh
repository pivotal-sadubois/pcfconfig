#!/bin/bash
# ############################################################################################
# File: ........: getPASSmallRuntime.sh
# Language .....: bash
# Author .......: Sacha Dubois, Pivotal
# Description ..: Dump PAS Release information into ../files/pas-release-notes.txt
# ############################################################################################

DIRNAME=$(dirname $0)
RELEASE_FILE=${DIRNAME}/../files/pas-srt-release-notes.txt
PRODUCT_SLUG=elastic-runtime


PIVNET=$(which pivnet)
if [ "${PIVNET}" == "" ]; then
  echo ""
  echo "ERROR: please install the pivnet utility from https://github.com/pivotal-cf/pivnet-cli"; exit 0
else
  # --- TEST FOR WORKING PIVNET UTILITY ---
  PIVNET_VERSION=$(PIVNET -v 2>/dev/null); ret=$?
  if [ "${PIVNET_VERSION}" == "" ]; then
    echo ""
    echo "ERROR: the pivnet utility $(which pivnet) does not seam to be correct"
    echo "       please install the om utility from https://github.com/pivotal-cf/pivnet-cli"; exit 0
  fi
fi

pivnet products > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo ""
  echo "ERROR: not logged in in PIVNET, please login with a new pivnet token"
  echo "       => pivnet login --api-token \"XXXXXXXXXXXXXXXXXXXXXXXXXXX\""
fi

echo "# GENETATED BY getPASSmallRuntime.sh (`date`)" > $RELEASE_FILE
LIST=$(pivnet --format=table releases --product-slug $PRODUCT_SLUG | \
     egrep " [0-9][0-9][0-9][0-9][0-9][0-9] " | awk '{ print $4 }' | head -10) 
for rel in $LIST; do
  echo "Download Release: $rel"
  pivnet --format=json product-files --product-slug $PRODUCT_SLUG -r $rel | jq > /tmp/$0_$$
  
  i=0; cnt=$(grep -c id /tmp/$0_$$)
  while [ $i -lt $cnt ]; do
    str=".[${i}]"
    id=$(jq "${str}.id" /tmp/$0_$$)
    nm=$(jq "${str}.name" /tmp/$0_$$ | sed 's/"//g')
    pf=$(jq "${str}.aws_object_key" /tmp/$0_$$ | sed 's/"//g' | awk -F'/' '{ print $NF }')
  
    cn=$(echo "$nm" | grep -c "Small Footprint PAS")
    ol=$(echo "$pf" | grep -c "open_source_license")
    if [ ${cn} -gt 0 -a ${ol} -eq 0 ]; then
      echo "$id:$rel:$nm:$pf" >> $RELEASE_FILE
    fi
  
    let i=i+1
  done
done



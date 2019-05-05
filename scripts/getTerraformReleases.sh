#!/bin/bash
# ############################################################################################
# File: ........: getTerraformReleases.sh
# Language .....: bash
# Author .......: Sacha Dubois, Pivotal
# Description ..: Dump Terraform Release information into ../files/terraform-release-notes.txt
# ############################################################################################

PRODUCT_SLUG=elastic-runtime
RELEASE_FILE=../files/terraform-release-notes.txt
LIST=$(pivnet --format=table releases --product-slug $PRODUCT_SLUG | \
       egrep " [0-9][0-9][0-9][0-9][0-9][0-9] " | awk '{ print $4 }' | head -10) 

mkdir -p /tmp/$0_pdf_$$

echo "# GENETATED BY getTerraformReleases.sh (`date`)" > $RELEASE_FILE

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

for rel in $LIST; do
  echo "Colecting information for $PRODUCT_SLUG release: $rel"
  $PIVNET --format=json product-files --product-slug $PRODUCT_SLUG -r $rel | jq > /tmp/$0_$$

  
  i=0; cnt=$(grep -c id /tmp/$0_$$)
  while [ $i -lt $cnt ]; do
    str=".[${i}]"
    id=$(jq "${str}.id" /tmp/$0_$$)
    nm=$(jq "${str}.name" /tmp/$0_$$ | sed 's/"//g')
    pf=$(jq "${str}.aws_object_key" /tmp/$0_$$ | sed 's/"//g' | awk -F'/' '{ print $NF }')

    aws=$(echo ${nm} | egrep -c "AWS Terraform Templates")
    gcp=$(echo ${nm} | egrep -c "GCP Terraform Templates")
    azc=$(echo ${nm} | egrep -c "Azure Terraform Templates")

    if [ ${aws} -gt 0 -o ${gcp} -gt 0 -o ${azc} -gt 0 ]; then
      echo "$id:$rel:$nm:$pf" >> $RELEASE_FILE
    fi

    let i=i+1
  done
  
  rm -f /tmp/$0_$$
done
rmdir /tmp/$0_pdf_$$


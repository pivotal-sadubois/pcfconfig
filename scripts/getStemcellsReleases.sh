#!/bin/bash
# ############################################################################################
# File: ........: getStemcellsReleases.sh
# Language .....: bash
# Author .......: Sacha Dubois, Pivotal
# Description ..: Dump Stemcells Release information into ../files/stemcell-release-notes.txt
# ############################################################################################

DIRNAME=$(dirname $0)
RELEASE_FILE=${DIRNAME}/../files/stemcell-release-notes.txt
PRODUCT_SLUG=stemcells-ubuntu-xenial
LIST=$(pivnet --format=table releases --product-slug $PRODUCT_SLUG | \
     egrep " [0-9][0-9][0-9][0-9][0-9][0-9] " | awk '{ print $4 }' | head -10) 

echo "# GENETATED BY getStemcellsReleases.sh (`date`)" > $RELEASE_FILE

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
  echo "Download Release: $rel"
  pivnet --format=json product-files --product-slug $PRODUCT_SLUG -r $rel | jq > /tmp/$0_$$
  
  i=0; cnt=$(grep -c id /tmp/$0_$$)
  while [ $i -lt $cnt ]; do
    str=".[${i}]"
    id=$(jq "${str}.id" /tmp/$0_$$)
    nm=$(jq "${str}.name" /tmp/$0_$$ | sed 's/"//g')
    pf=$(jq "${str}.aws_object_key" /tmp/$0_$$ | sed 's/"//g' | awk -F'/' '{ print $NF }')

    found=0
    aws=$(echo $nm | egrep -c AWS)
    gcp=$(echo $nm | egrep -c "Google Cloud Platform")
    osp=$(echo $nm | egrep -c "Openstack")
    azc=$(echo $nm | egrep -c "Azure")
    vcl=$(echo $nm | egrep -c "vCloud")
    vsp=$(echo $nm | egrep -c "vSphere")

    if [ ${aws} -gt 0 ]; then typ=aws; found=1; fi
    if [ ${gcp} -gt 0 ]; then typ=gcp; found=1; fi
    if [ ${osp} -gt 0 ]; then typ=osp; found=1; fi
    if [ ${azc} -gt 0 ]; then typ=azure; found=1; fi
    if [ ${vcl} -gt 0 ]; then typ=vcloud; found=1; fi
    if [ ${vsp} -gt 0 ]; then typ=vsphere; found=1; fi
  
    cn=$(echo "$nm" | grep -c "Ubuntu Xenial Stemcell")
    if [ ${cn} -gt 0 -a ${found} -gt 0 ]; then
      echo "$id:$rel:$typ:$nm:$pf" >> $RELEASE_FILE
      echo "$id:$rel:$typ:$nm:$pf"
    fi
  
    let i=i+1
  done
done



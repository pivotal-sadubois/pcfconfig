#!/bin/bash
# ############################################################################################
# File: ........: getOpsManagerReleases.sh
# Language .....: bash
# Author .......: Sacha Dubois, Pivotal
# Description ..: Dump OpsMan Release information into ../files/opsman-release-notes.txt
# ############################################################################################

DIRNAME=$(dirname $0)
RELEASE_FILE=${DIRNAME}/../files/opsman-release-notes.txt
PRODUCT_SLUG=ops-manager
LIST=$(pivnet --format=table releases --product-slug $PRODUCT_SLUG | \
     egrep "^\| [0-9]* \|" | awk '{ print $4 }' | head -10) 

echo "# GENETATED BY getOpsManagerReleases.sh (`date`)" > $RELEASE_FILE

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

pivnet --format=json releases --product-slug $PRODUCT_SLUG > /tmp/$$_rel
cp /tmp/$$_rel /tmp/rel

for rel in $LIST; do
  echo "Download Release: $rel"
  pivnet --format=json product-files --product-slug $PRODUCT_SLUG -r $rel | jq > /tmp/$0_$$
  
  i=0; cnt=$(grep -c id /tmp/$0_$$)
  while [ $i -lt $cnt ]; do
    str=".[${i}]"
    id=$(jq "${str}.id" /tmp/$0_$$)
    nm=$(jq "${str}.name" /tmp/$0_$$ | sed 's/"//g')
    pf=$(jq "${str}.aws_object_key" /tmp/$0_$$ | sed 's/"//g' | awk -F'/' '{ print $NF }')
    
    cn=$(echo "$pf" | grep -c "\.yml") 
    if [ ${cn} -gt 0 ]; then
      aws=$(echo ${nm} | egrep -c "Ops Manager YAML for AWS")
      gcp=$(echo ${nm} | egrep -c "Ops Manager YAML for GCP")
      azc=$(echo ${nm} | egrep -c "Ops Manager YAML for Azure")
      [ ${aws} -gt 0 ] && cld="aws"
      [ ${gcp} -gt 0 ] && cld="gcp"
      [ ${azc} -gt 0 ] && cld="azure"

      pivnet --format=json release --product-slug $PRODUCT_SLUG -r $rel > /tmp/$$_rel 2>/dev/null
      rdt=$(jq -r '.release_date' /tmp/$$_rel)
      eos=$(jq -r '.end_of_support_date' /tmp/$$_rel)
      des=$(jq -r '.description' /tmp/$$_rel)

      if [ ${aws} -gt 0 -o ${gcp} -gt 0 -o ${azc} -gt 0 ]; then
        ver=$(echo "${des}" | awk '{ print $(NF) }')
        pivnet download-product-files --download-dir=/tmp --product-slug ops-manager -r $rel -i $id  >/dev/null 2>&1
        if [ ${gcp} -gt 0 ]; then 
          egrep "\.gz" /tmp/$pf | sed 's/: /:/g' | \
          awk -F: '{ printf("%s,%s,%s,%s,%s,%s,%s\n",rel,ver,cld,$1,$2,rdt,eos )}' \
             rel=$rel ver=$ver cld=$cld rdt=$rdt eos=$eos >> $RELEASE_FILE
        fi

        if [ ${azc} -gt 0 ]; then 
          egrep "\.vhd" /tmp/$pf | sed 's/: /,/g' | \
          awk -F',' '{ printf("%s,%s,%s,%s,%s,%s,%s\n",rel,ver,cld,$1,$2,rdt,eos )}' \
              rel=$rel ver=$ver cld=$cld rdt=$rdt eos=$eos >> $RELEASE_FILE
        fi

        if [ ${aws} -gt 0 ]; then 
          egrep "ami" /tmp/$pf | sed 's/: /:/g' | \
          awk -F: '{ printf("%s,%s,%s,%s,%s,%s,%s\n",rel,ver,cld,$1,$2,rdt,eos )}' \
              rel=$rel ver=$ver cld=$cld rdt=$rdt eos=$eos >> $RELEASE_FILE
        fi

        rm -f /tmp/$pf /tmp/$$_rel
      fi
    fi
  
    let i=i+1
  done
done

rm -f /tmp/$$_rel


#!/bin/bash

DOWNLOAD_PDF=0
CONVERT_PDF=0
LIST=$(pivnet --format=table releases --product-slug ops-manager | grep "Ops Manager build version" | awk '{ print $4 }')

mkdir -p /tmp/$0_pdf_$$

if [ $DOWNLOAD_PDF -eq 1 ]; then
  PIVNET=$(which pivnet)
  if [ "${PIVNET}" == "" ]; then
    echo ""
    echo "ERROR: please install the pivnet utility from https://github.com/pivotal-cf/pivnet-cli"; exit 0
  else
    # --- TEST FOR WORKING PIVNET UTILITY ---
    PIVNET_VERSION=$(PIVNET -v 2>/dev/null); ret=$?
    if [ "${PIVNET_VERSION}" -ne "" ]; then
      echo ""
      echo "ERROR: the pivnet utility $(which pivnet) does not seam to be correct"
      echo "       please install the om utility from https://github.com/pivotal-cf/pivnet-cli"; exit 0
    fi
  fi

  for rel in $LIST; do
    echo "Download Release: $rel"
    pivnet --format=json product-files --product-slug ops-manager -r $rel | jq > /tmp/$0_$$
  
    i=0; cnt=$(grep -c id /tmp/$0_$$)
    while [ $i -lt $cnt ]; do
      str=".[${i}]"
      id=$(jq "${str}.id" /tmp/$0_$$)
      nm=$(jq "${str}.name" /tmp/$0_$$)
  
      cn=$(echo "$nm" | grep -c "Ops Manager for AWS")
      if [ ${cn} -gt 0 ]; then
        pivnet download-product-files --download-dir=/tmp/$0_pdf_$$ --product-slug ops-manager -r $rel -i $id > /dev/null 2>&1     
        file=$(ls -1 /tmp/$0_pdf_$$/* | awk -F'/' '{ print $NF }') 
        mv /tmp/$0_pdf_$$/${file} ./opsman-release/${rel}-${file} 
      fi
  
      let i=i+1
    done
  
    rm -f /tmp/$0_$$
  done
  rmdir /tmp/$0_pdf_$$
fi

if [ $CONVERT_PDF -eq 1 ]; then
  for n in $(ls -1 opsman-release); do
    file=$(echo $n | sed 's/pdf/txt/g')
    pdftotext -simple opsman-release/${n} opsman-release/$file
  done
fi

# --- PARSE FILES ---
rm -f opsman-release-notes.txt
for n in $(ls -1 opsman-release | grep txt); do
  fil=$(echo $n | sed -e 's/ops-manager-aws-/OpsManager/g' -e 's/onAWS//g' -e 's/build\.//g')
  rel=$(echo $fil | awk -F'-' '{ print $1 }')
  bld=$(echo $fil | awk -F'-' '{ print $3 }' | awk -F'.' '{ print $1 }')

  cat "opsman-release/${n}" | strings | grep ami | sed -e 's/^  //g' -e 's/ \*\* /:/g' -e 's/ \*\*//g' -e 's/ (/:/g' -e 's/)//g' -e 's/::/:/g' | \
  awk '{ printf("%s:%s:%s\n", a, b, $0 )}' a=${rel} b=${bld} >> opsman-release-notes.txt
done





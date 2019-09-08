#!/bin/bash

stt=1
while [ $stt -ne 0 ]; do
  az group list > /dev/null 2>&1; stt=$?
  if [ $stt -ne 0 ]; then
    az login 
  fi
done

exit 0

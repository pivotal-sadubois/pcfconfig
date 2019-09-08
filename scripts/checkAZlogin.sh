#!/bin/bash

stt=0
while [ $stt -ne 0 ]; do
  az group list > /dev/null 2>&1; stt=$?
  if [ stt -ne 0 ]; then
    az login
    stt=$?
  fi
done

exit 0

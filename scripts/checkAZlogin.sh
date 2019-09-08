#!/bin/bash
echo xxxxxx

stt=1
while [ $stt -ne 0 ]; do
  az group list > /dev/null 2>&1; stt=$?
echo gaga1
  if [ $stt -ne 0 ]; then
echo gaga2
    az login > /dev/null 2>&1
  fi
done

exit 0

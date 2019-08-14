#!/bin/bash

cd $HOME
if [ -f ~/nohup.out ]; then
  cnt=$(egrep -c "################################ EOF ################################" ~/nohup.out)
  if [ $cnt -gt 0 ]; then 
    cat ~/nohup.out
    exit 0
  fi
fi

if [ -f ~/pcfconfig.pid ]; then
  read pid < ~/pcfconfig.pid
  cnt=$(ps -p $pid -o pid,comm | sed 1d | grep -c " ${pid} ") 
  if [ $cnt -eq 0 ]; then 
    [ -f ~/nohup.out ] && rm -f ~/nohup.out
    nohup /tmp/tttt 2>/dev/null &
    #nohup ~/pcfconfig/pcfconfig $* 2>/dev/null &
    echo $! > ~/pcfconfig.pid
  fi
else
  [ -f ~/nohup.out ] && rm -f ~/nohup.out
  nohup /tmp/tttt 2>/dev/null &
  #nohup ~/pcfconfig/pcfconfig $* 2>/dev/null &
  echo $! > ~/pcfconfig.pid
fi

sleep 2
if [ -f ~/nohup.out ]; then
  tail -100f ~/nohup.out
fi

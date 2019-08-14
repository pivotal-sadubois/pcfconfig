#!/bin/bash

LOGFILE=/tmp/pcfconfig.log
PIDFILE=/tmp/pcfconfig.pid
COMMAND="~/pcfconfig/pcfconfig $*"
COMMAND=/tmp/tttt 

cd $HOME

if [ -f $PIDFILE ]; then
  read pid < $PIDFILE
  cnt=$(ps -p $pid -o pid,comm | sed 1d | grep -c " ${pid} ") 
  if [ $cnt -eq 0 ]; then 
    nohup $COMMAND > $LOGFILE 2>&1 &
    echo $! > $PIDFILE
  fi
else
  nohup $COMMAND > $LOGFILE 2>&1 &
  echo $! > $PIDFILE
fi

sleep 2
if [ -f $LOGFILE ]; then
  read pid < $PIDFILE
  tail -1000f $LOGFILE --pid $pid
fi

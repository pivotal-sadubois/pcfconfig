#!/bin/bash

LOGFILE=/tmp/pcfconfig.log
PIDFILE=/tmp/pcfconfig.pid
COMMAND="~/pcfconfig/pcfconfig $*"
COMMAND=/tmp/tttt 

cd $HOME
if [ -f $LOGFILE ]; then
  cnt=$(egrep -c "################################ EOF ################################" $LOGFILE)
  if [ $cnt -gt 0 ]; then 
    cat $LOGFILE
    exit 0
  fi
fi

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
echo "tail --pid $pid -100f $LOGFILE"
  tail --pid $pid -100f $LOGFILE
fi

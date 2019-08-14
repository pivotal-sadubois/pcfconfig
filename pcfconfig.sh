#!/bin/bash

LOGFILE=/tmp/pcfconfig.log
PIDFILE=/tmp/pcfconfig.pid
COMMAND=/tmp/tttt 
COMMAND="$HOME/pcfconfig/pcfconfig $*"

if [ -f $PIDFILE ]; then
  stt=$(pgrep -F /tmp/pcfconfig.pid)
  if [ "$stt" == "" ]; then 
    echo "$0 NOT RUNNING, RESTARTING"
    date +%s > $LOGFILE
    nohup $COMMAND >> $LOGFILE 2>&1 &
    echo $! > $PIDFILE
  fi
else
  echo "$0 1NOT RUNNING, RESTARTING"
  date +%s > $LOGFILE
  nohup $COMMAND >> $LOGFILE 2>&1 &
  echo $! > $PIDFILE
fi

sleep 2
if [ -f $LOGFILE ]; then
  read pid < $PIDFILE
  tail -n 1000 -f $LOGFILE --pid $pid
fi

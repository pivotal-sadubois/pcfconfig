#!/bin/bash
# ############################################################################################
# File: ........: deployPCFwrapper.sh
# Language .....: bash
# Author .......: Sacha Dubois, Pivotal
# Description ..: SSH Wrapper for deployPCFremote.sh
# ############################################################################################


LOGFILE=/tmp/pcfconfig.log
PIDFILE=/tmp/pcfconfig.pid
COMMAND=$HOME/pcfconfig/scripts/deployPCFremote.sh
ARGS="$*"

eof=0

if [ -f $LOGFILE ]; then
  eof=$(egrep -c "################################ EOF ################################" $LOGFILE)
eof=0
  if [ $eof -gt 0 ]; then 
    cat $LOGFILE
    exit
  fi
fi 

if [ -f $PIDFILE ]; then
  stt=$(pgrep -F /tmp/pcfconfig.pid)
  if [ "$stt" == "" ]; then 
    echo "$0 NOT RUNNING, RESTARTING"
    #nohup $COMMAND $ARGS >> $LOGFILE 2>&1 &
    
    # --- ROTATE LOGFILE ---
    [ -f /tmp/pcfconfig.log.4 ] && mv /tmp/pcfconfig.log.4 /tmp/pcfconfig.log.5
    [ -f /tmp/pcfconfig.log.3 ] && mv /tmp/pcfconfig.log.3 /tmp/pcfconfig.log.4
    [ -f /tmp/pcfconfig.log.2 ] && mv /tmp/pcfconfig.log.2 /tmp/pcfconfig.log.3
    [ -f /tmp/pcfconfig.log.1 ] && mv /tmp/pcfconfig.log.1 /tmp/pcfconfig.log.2
    [ -f /tmp/pcfconfig.log   ] && mv /tmp/pcfconfig.log   /tmp/pcfconfig.log.1
    echo "Logfile: /tmp/pcfconfig.log rotated to /tmp/pcfconfig.log.1" > $LOGFILE

    $COMMAND $ARGS >> $LOGFILE 2>&1 &
    echo $! > $PIDFILE
  fi
else
  echo "$0 WAS NEVER RUNNING, 1st START"
  date +%s > $LOGFILE
  #nohup $COMMAND $ARGS >> $LOGFILE 2>&1 &
  $COMMAND $ARGS >> $LOGFILE 2>&1 &
  echo $! > $PIDFILE
fi

sleep 2
#if [ -f $LOGFILE ]; then
#  read pid < $PIDFILE
#  tail -n 1000 -f $LOGFILE --pid $pid
#fi

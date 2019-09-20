#!/bin/bash
# ============================================================================================
# File: ........: deploy_demo.sh
# Language .....: bash
# Author .......: Sacha Dubois, Pivotal
# --------------------------------------------------------------------------------------------
# Description ..: Demonstration for Ingress Routing based on two different URL
# ============================================================================================

BASENAME=$(basename $0)
DIRNAME=$(dirname $0)

if [ -f ${DIRNAME}/../../functions ]; then 
  . ${DIRNAME}/../../functions
else
  echo "ERROR: can ont find ${DIRNAME}/../../functions"; exit 1
fi

cf apps > /dev/null 2>&1
if [ $? -ne 0 ]; then 
  echo "ERROR: Please login to your CloudFoundry environment"
  exit 1
fi

# Created by /usr/local/bin/figlet
clear
echo '                                                                                       '
echo '              _         _   _            _       _          ____                       '         
echo '             / \   _ __| |_(_) ___ _   _| | __ _| |_ ___   |  _ \  ___ _ __ ___   ___  '
echo '            / _ \ |  __| __| |/ __| | | | |/ _  | __/ _ \  | | | |/ _ \  _   _ \ / _ \ '
echo '           / ___ \| |  | |_| | (__| |_| | | (_| | ||  __/  | |_| |  __/ | | | | | (_) |'
echo '          /_/   \_\_|   \__|_|\___|\__,_|_|\__,_|\__\___|  |____/ \___|_| |_| |_|\___/ '
echo '                                                                                       '
echo '          ---------------------------------------------------------------------------- '
echo '                Demonstration Microservices, PCF Marketplace and service bindings'
echo '                                    by Sacha Dubois, Pivotal Inc                       '
echo '          ---------------------------------------------------------------------------- '
echo '                                                                                       '

#tocindex=1

# SETUP DEMO ENVIRONMENT
DEMO_PATH=/tmp/pas-demo-articulate; mkdir -p $DEMO_PATH
cp *.jar /tmp/pas-demo-articulate; cd $DEMO_PATH

prtHead "These are the two application we are going to deploy"
execCmd "ls $DEMO_PATH"

prtHead "Let's push the application 'articulate' to PCF"
execCmd "cf push articulate -p ./articulate-0.2.jar -m 768M -n articulate-workshop"
execCmd "cf apps"
execCmd "cf open articulate"

prtHead "We need to deploy a MySQL backend service for the attendee-service"
execCmd "cf marketplace -s p.mysql"
execCmd "cf create-service p.mysql db-small attendee-mysql"
execCmd "cf services"

prtHead "Let's deploy the attendee-service, but dont sart it yet"
execCmd "cf push attendee-service -p ./attendee-service-0.1.jar -m 768M -n articulate-attendee-service --no-start"
execCmd "cf app attendee-service"

prtHead "We scale now the available memory of the 'articulate' application"
execCmd "cf scale articulate -m 1G -f"
execCmd "cf app articulate"

prtHead "Scale application to 3 instances to gain redundancy"
execCmd "cf scale articulate -i 3"
execCmd "cf app articulate"

prtHead "Wait for the attendee-mysql to be deployed successfuly"
stt=""
while [ "${stt}" != "create succeeded" ]; do 
  execCmd "cf service attendee-mysql"
  stt=$(cf service attendee-mysql 2>/dev/null | egrep "^status" | sed 's/status:  *//g')
done

prtHead "Now we bind the MySQL db 'attendee-mysql to the 'attendee-service' application"
execCmd "cf bind-service attendee-service attendee-mysql"
#execCmd "cf restage attendee-service"
execCmd "cf start attendee-service"

prtHead "Now we need to bind the dataase service 'attendee-mysql' with the service instance 'attendee-service'"
url=$(cf apps | grep "^attendee-service" | awk '{ print $NF }')
execCmd "cf create-user-provided-service attendee-service -p '{\"uri\":\"https://$url/\"}'"

prtHead "And now we can bind articulate application to our attendee-service"
execCmd "cf bind-service articulate attendee-service"
execCmd "cf services"

prtHead "Now we need to restart the 'articulate' application"
execCmd "cf restart articulate"

prtHead "Now we need to restart the 'articulate' application"
execCmd "cf routes"

exit


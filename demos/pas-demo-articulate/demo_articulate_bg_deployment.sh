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

cf app articulate > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "ERROR: Please run demo_articulate.sh first app 'articulate' is not yet staged"
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
echo '                             Demonstration Blue/Green deployments '
echo '                                 by Sacha Dubois, Pivotal Inc                       '
echo '          ---------------------------------------------------------------------------- '
echo '                                                                                       '

tocindex=""
#waitCmd 

# SETUP DEMO ENVIRONMENT
DEMO_PATH=/tmp/pas-demo-articulate; mkdir -p $DEMO_PATH; cd $DEMO_PATH

prtHead "We have already deployed the 'articulate' applocation with the 'attendee-service' service"
execCmd "cf apps"
execCmd "cf routes"

prtHead "let’s push the next version of articulate. We will specify the subdomain by"
prtText "appending -temp to our production route."
execCmd "cf push articulate-v2 -p ./articulate-0.2.jar -m 768M -n articulate-workshop-temp --no-manifest --no-start"
execCmd "cf apps"

prtHead "bind the new deployed articulate-v2 application to our attendee-service"
execCmd "cf bind-service articulate-v2 attendee-service"
execCmd "cf start articulate-v2"
execCmd "cf services"
execCmd "cf routes"

url=$(cf apps | grep "articulate-v2" | awk '{ print $NF }')
prtHead "Verify articulate-v2 by acessing the temporary route $url."
prtText "You will see 'articulate-v2' as the application name."
prtText ""
prtText "=> http://$url"
prtText ""
execCmd "cf open articulate-v2"

prtHead "We need to map our production route to articulate-v2"
dmn=$(cf routes | grep " articulate-workshop " | awk '{ print $3 }') 
execCmd "cf routes"
prtText "(Start the load-generator in the articulate app under 'Blue-Green Deployment')"
execCmd "cf map-route articulate-v2 ${dmn} --hostname articulate-workshop"
execCmd "cf routes"

prtHead "Scale down 'articulate' to 1 instances"
execCmd "cf scale articulate -i 1"
execCmd "cf apps"

prtHead "Scale up 'articulate-v2' to 3 instances"
execCmd "cf scale articulate-v2 -i 3"
execCmd "cf apps"

prtHead "Scale down 'articulate' to 0 instances"
execCmd "cf scale articulate -i 0"
execCmd "cf apps"




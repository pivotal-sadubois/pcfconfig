cf unmap-route articulate-v2 apps.pcfone.io --hostname articulate-workshop
cf routes > /tmp/cfroutes
for host in articulate-workshop articulate-temp articulate-attendee-service; do
  cnt=$(egrep -c " $host " /tmp/cfroutes)
  if [ $cnt -gt 0 ]; then 
    dom=$(egrep " $host " /tmp/cfroutes | awk '{ print $3 }')
    echo "cf delete-route $dom --hostname $host -f"
  fi
done

rm -f /tmp/cfroutes

cf delete articulate -f
cf delete articulate-v2 -f
cf delete attendee-service -f

cf delete-service attendee-service -f
cf delete-service attendee-mysql -f

dmn=$(cf routes | grep " articulate-workshop " | awk '{ print $3 }')
cf delete-route $dmn --hostname articulate-workshop -f
cf delete-route $dmn --hostname articulate-attendee-service -f
cf apps
cf services
cf routes


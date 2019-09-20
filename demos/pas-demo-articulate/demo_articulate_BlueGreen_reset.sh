cf unmap-route articulate-v2 apps.pcfone.io --hostname articulate-workshop
cf delete-route articulate-workshop-temp 
cf delete articulate-v2 -f
cf delete-route apps.pcfone.io --hostname articulate-workshop-temp -f
cf scale articulate -i 3
cf apps
cf services

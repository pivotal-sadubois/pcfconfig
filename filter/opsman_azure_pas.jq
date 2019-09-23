# IAAS_CONFIGURATION
"vms_security_group_name: " + .modules[].outputs.bosh_deployed_vms_security_group_name.value,
"pcf_resource_group_name: " + .modules[].outputs.pcf_resource_group_name.value,
"bosh_root_storage_account: " + .modules[].outputs.bosh_root_storage_account.value,
"ops_manager_ssh_private_key: <1>" + .modules[].outputs.ops_manager_ssh_private_key.value + "<1>",
"ops_manager_ssh_public_key: <1>" + .modules[].outputs.ops_manager_ssh_public_key.value + "<1>",
"aws-region: " + .modules[].outputs.region.value,
"encrypted: false", 

# DIRECTOR_CONFIGURATION
"ntp_servers_string: 0.amazon.pool.ntp.org",
"network_name: " + .modules[].outputs.network_name.value,

# INFRASTRUCTURE-SUBNET
"infrastructure_subnet_cid: " + .modules[].outputs.infrastructure_subnet_cidr.value,
"infrastructure_subnet_name: " + .modules[].outputs.infrastructure_subnet_name.value,
"infrastructure_subnet_gateway: " + .modules[].outputs.infrastructure_subnet_gateway.value,
"infrastructure_subnet_ids: " + .modules[].outputs.infrastructure_subnet_ids.value[0],
"infrastructure_subnet_dns: " + "168.63.129.16",

# PKS-SUBNET
"pas_subnet_cidr: " + .modules[].outputs.pas_subnet_cidr.value,
"pas_subnet_name: " + .modules[].outputs.pas_subnet_name.value,
"pas_subnet_gateway: " + .modules[].outputs.pas_subnet_gateway.value,
"pas_subnet_ids: " + .modules[].outputs.pas_subnet_ids.value[0],
"pas_subnet_dns: " + "168.63.129.16",

# SERVICES-SUBNET
"services_subnet_cidr: " + .modules[].outputs.services_subnet_cidr.value,
"services_subnet_name: " + .modules[].outputs.services_subnet_name.value,
"services_subnet_gateway: " + .modules[].outputs.services_subnet_gateway.value,
"services_subnet_ids: " + .modules[].outputs.services_subnet_ids.value[0],
"services_subnet_dns: " + "168.63.129.16"

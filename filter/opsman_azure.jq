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

# INFRASTRUCTURE-SUBNET
"infrastructure_subnet_cid: " + .modules[].outputs.infrastructure_subnet_cidr.value,
"infrastructure_subnet_name: " + .modules[].outputs.infrastructure_subnet_name.value,
"infrastructure_subnet_gateway: " + .modules[].outputs.infrastructure_subnet_gateway.value,
"infrastructure_subnet_ids: " + .modules[].outputs.infrastructure_subnet_ids.value[0],
"infrastructure_subnet_dns: " + "10.0.0.2",
"infrastructure_subnet_range: " + "10.0.16.0-10.0.16.4",

# PKS-SUBNET
"pks_subnet_cidr: " + .modules[].outputs.pks_subnet_cidr.value,
"pks_subnet_name: " + .modules[].outputs.pks_subnet_name.value,
"pks_subnet_gateway: " + .modules[].outputs.pks_subnet_gateway.value,
"pks_subnet_ids: " + .modules[].outputs.pks_subnet_ids.value[0],
"pks_subnet_dns: " + "10.0.0.2",
"pks_subnet_range: " + "10.0.4.0-10.0.4.9",

# SERVICES-SUBNET
"services_subnet_cidr: " + .modules[].outputs.services_subnet_cidr.value,
"services_subnet_name: " + .modules[].outputs.services_subnet_name.value,
"services_subnet_gateway: " + .modules[].outputs.services_subnet_gateway.value,
"services_subnet_ids: " + .modules[].outputs.services_subnet_ids.value[0],
"services_subnet_dns: " + "10.0.0.2",
"services_subnet_range: " + "10.0.8.0-10.0.8.9"

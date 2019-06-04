# IAAS_CONFIGURATION
"vms_security_group_id: " + .modules[].outputs.vms_security_group_id.value,
#"ops_manager_ssh_public_key_name: " + .modules[].outputs.ops_manager_ssh_public_key_name.value,
"ops_manager_ssh_public_key_name: " + .modules[].outputs.ssh_public_key_name.value,
#"ops_manager_ssh_private_key: <1>" + .modules[].outputs.ops_manager_ssh_private_key.value + "<1>",
"ops_manager_ssh_private_key: <1>" + .modules[].outputs.ssh_private_key.value + "<1>",
#"aws-region: " + .modules[].outputs.region.value,
"encrypted: false", 

# DIRECTOR_CONFIGURATION
"ntp_servers_string: 0.amazon.pool.ntp.org",

# INFRASTRUCTURE-SUBNET
"infrastructure_subnet_1_cidrs: " + .modules[].outputs.infrastructure_subnet_cidrs.value[0],
"infrastructure_subnet_1_azname: " + .modules[].outputs.infrastructure_subnet_availability_zones.value[0],
"infrastructure_subnet_1_gateway: " + .modules[].outputs.infrastructure_subnet_gateways.value[0],
"infrastructure_subnet_1_ids: " + .modules[].outputs.infrastructure_subnet_ids.value[0],
"infrastructure_subnet_1_dns: " + "10.0.0.2",
"infrastructure_subnet_1_range: " + "10.0.16.0-10.0.16.4",

"infrastructure_subnet_2_cidrs: " + .modules[].outputs.infrastructure_subnet_cidrs.value[1],
"infrastructure_subnet_2_azname: " + .modules[].outputs.infrastructure_subnet_availability_zones.value[1],
"infrastructure_subnet_2_gateway: " + .modules[].outputs.infrastructure_subnet_gateways.value[1],
"infrastructure_subnet_2_ids: " + .modules[].outputs.infrastructure_subnet_ids.value[1],
"infrastructure_subnet_2_dns: " + "10.0.0.2",
"infrastructure_subnet_2_range: " + "10.0.16.16-10.0.16.20",

"infrastructure_subnet_3_cidrs: " + .modules[].outputs.infrastructure_subnet_cidrs.value[2],
"infrastructure_subnet_3_azname: " + .modules[].outputs.infrastructure_subnet_availability_zones.value[2],
"infrastructure_subnet_3_gateway: " + .modules[].outputs.infrastructure_subnet_gateways.value[2],
"infrastructure_subnet_3_ids: " + .modules[].outputs.infrastructure_subnet_ids.value[2],
"infrastructure_subnet_3_dns: " + "10.0.0.2",
"infrastructure_subnet_3_range: " + "10.0.16.32-10.0.16.36",

# PKS-SUBNET
"pks_subnet_1_cidrs: " + .modules[].outputs.pks_subnet_cidrs.value[0],
"pks_subnet_1_azname: " + .modules[].outputs.pks_subnet_availability_zones.value[0],
"pks_subnet_1_gateway: " + .modules[].outputs.pks_subnet_gateways.value[0],
"pks_subnet_1_ids: " + .modules[].outputs.pks_subnet_ids.value[0],
"pks_subnet_1_dns: " + "10.0.0.2",
"pks_subnet_1_range: " + "10.0.4.0-10.0.4.9",

"pks_subnet_2_cidrs: " + .modules[].outputs.pks_subnet_cidrs.value[1],
"pks_subnet_2_azname: " + .modules[].outputs.pks_subnet_availability_zones.value[1],
"pks_subnet_2_gateway: " + .modules[].outputs.pks_subnet_gateways.value[1],
"pks_subnet_2_ids: " + .modules[].outputs.pks_subnet_ids.value[1],
"pks_subnet_2_dns: " + "10.0.0.2",
"pks_subnet_2_range: " + "10.0.5.0-10.0.5.9",

"pks_subnet_3_cidrs: " + .modules[].outputs.pks_subnet_cidrs.value[2],
"pks_subnet_3_azname: " + .modules[].outputs.pks_subnet_availability_zones.value[2],
"pks_subnet_3_gateway: " + .modules[].outputs.pks_subnet_gateways.value[2],
"pks_subnet_3_ids: " + .modules[].outputs.pks_subnet_ids.value[2],
"pks_subnet_3_dns: " + "10.0.0.2",
"pks_subnet_3_range: " + "10.0.6.0-10.0.6.9",

# SERVICES-SUBNET
"services_subnet_1_cidrs: " + .modules[].outputs.services_subnet_cidrs.value[0],
"services_subnet_1_azname: " + .modules[].outputs.services_subnet_availability_zones.value[0],
"services_subnet_1_gateway: " + .modules[].outputs.services_subnet_gateways.value[0],
"services_subnet_1_ids: " + .modules[].outputs.services_subnet_ids.value[0],
"services_subnet_1_dns: " + "10.0.0.2",
"services_subnet_1_range: " + "10.0.8.0-10.0.8.9",

"services_subnet_2_cidrs: " + .modules[].outputs.services_subnet_cidrs.value[1],
"services_subnet_2_azname: " + .modules[].outputs.services_subnet_availability_zones.value[1],
"services_subnet_2_gateway: " + .modules[].outputs.services_subnet_gateways.value[1],
"services_subnet_2_ids: " + .modules[].outputs.services_subnet_ids.value[1],
"services_subnet_2_dns: " + "10.0.0.2",
"services_subnet_2_range: " + "10.0.9.0-10.0.9.9",

"services_subnet_3_cidrs: " + .modules[].outputs.services_subnet_cidrs.value[2],
"services_subnet_3_azname: " + .modules[].outputs.services_subnet_availability_zones.value[2],
"services_subnet_3_gateway: " + .modules[].outputs.services_subnet_gateways.value[2],
"services_subnet_3_ids: " + .modules[].outputs.services_subnet_ids.value[2],
"services_subnet_3_dns: " + "10.0.0.2",
"services_subnet_3_range: " + "10.0.10.0-10.0.10.9"



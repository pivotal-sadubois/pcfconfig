# IAAS_CONFIGURATION
"project: " + .modules[].outputs.project.value,
"associated_service_account: " + .modules[].outputs.service_account_email.value,
"vms_security_group_id: " + .modules[].outputs.vms_security_group_id.value,
"ops_manager_ssh_public_key_name: " + .modules[].outputs.ops_manager_ssh_public_key.value,
"ops_manager_ssh_private_key: <1>" + .modules[].outputs.ops_manager_ssh_private_key.value + "<1>",
"encrypted: false", 

"zone-1: " + .modules[].outputs.azs.value[0],
"zone-2: " + .modules[].outputs.azs.value[1],
"zone-3: " + .modules[].outputs.azs.value[2],

# DIRECTOR_CONFIGURATION
"network_name: " + .modules[].outputs.network_name.value,

# INFRASTRUCTURE-SUBNET
"infrastructure_subnet_cidr: " + .modules[].outputs.infrastructure_subnet_cidr.value,
"infrastructure_subnet_name: " + .modules[].outputs.infrastructure_subnet.value,
"infrastructure_subnet_gateway: " + .modules[].outputs.infrastructure_subnet_gateway.value,

# PKS-SUBNET
"pks_subnet_cidr: " + .modules[].outputs.pks_subnet_cidr.value,
"pks_subnet_name: " + .modules[].outputs.pks_subnet_name.value,
"pks_subnet_gateway: " + .modules[].outputs.pks_subnet_gateway.value,

# SERVICES-SUBNET
"services_subnet_cidr: " + .modules[].outputs.services_subnet_cidr.value,
"services_subnet_name: " + .modules[].outputs.services_subnet_name.value,
"services_subnet_gateway: " + .modules[].outputs.services_subnet_gateway.value


[bastion]
${bastion_name} ansible_host=${bastion_ip} ansible_user=opc role=bastion
[storage]
%{ for host, ip in storage ~}
${host} ansible_host=${ip} ansible_user=opc role=storage
%{ endfor ~}
[management]
%{ for host, ip in management ~}
${host} ansible_host=${ip} ansible_user=opc role=management
%{ endfor ~}
[metadata]
%{ for host, ip in metadata ~}
${host} ansible_host=${ip} ansible_user=opc role=metadata
%{ endfor ~}
[compute]
%{ for host, ip in compute ~}
${host} ansible_host=${ip} ansible_user=opc role=compute
%{ endfor ~}
[all:children]
bastion
storage
management
metadata
compute
[all:vars]
ansible_connection=ssh
ansible_user=opc
rdma_network=192.168.168.0
rdma_netmask=255.255.252.0
fs_name=${fs_name}
fs_type=${fs_type}
vcn_domain_name=${vcn_domain_name}
public_subnet=${public_subnet} 
private_storage_subnet_dns_label=${private_storage_subnet_dns_label}
private_fs_subnet_dns_label=${private_fs_subnet_dns_label}
filesystem_subnet_domain_name=${filesystem_subnet_domain_name}
storage_subnet_domain_name=${storage_subnet_domain_name}
management_server_filesystem_vnic_hostname_prefix=${management_server_filesystem_vnic_hostname_prefix}
metadata_server_filesystem_vnic_hostname_prefix=${metadata_server_filesystem_vnic_hostname_prefix}
storage_server_filesystem_vnic_hostname_prefix=${storage_server_filesystem_vnic_hostname_prefix}
derived_management_server_disk_count=${derived_management_server_disk_count}
derived_management_server_node_count=${derived_management_server_node_count}
derived_metadata_server_node_count=${derived_metadata_server_node_count}
derived_metadata_server_disk_count=${derived_metadata_server_disk_count}
storage_server_node_count=${storage_server_node_count}
storage_tier_1_disk_perf_tier=${storage_tier_1_disk_perf_tier}
stripe_size=${stripe_size}
mount_point=${mount_point}


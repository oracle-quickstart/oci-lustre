

data "oci_core_instance" "storage_server" {
  count       = var.storage_server_node_count
  instance_id = element(concat(oci_core_instance.storage_server.*.id, [""]), count.index)
}

data "oci_core_instance" "metadata_server" {
  count       = local.derived_metadata_server_node_count
  instance_id = element(concat(oci_core_instance.metadata_server.*.id, [""]), count.index)
}

data "oci_core_instance" "management_server" {
  count       = local.derived_management_server_node_count
  instance_id = element(concat(oci_core_instance.management_server.*.id, [""]), count.index)
}

data "oci_core_instance" "client_node" {
  count       = var.client_node_count
  instance_id = element(concat(oci_core_instance.client_node.*.id, [""]), count.index)
}


data "oci_core_subnet" "private_storage_subnet" {
  subnet_id = local.storage_subnet_id
}

data "oci_core_subnet" "private_fs_subnet" {
  subnet_id = local.fs_subnet_id
}


data "oci_core_subnet" "public_subnet" { 
  subnet_id = local.bastion_subnet_id
} 

data "oci_core_vcn" "hfs" {
  vcn_id = var.use_existing_vcn ? var.vcn_id : oci_core_virtual_network.hfs[0].id
}

output "bastion" {
  value = oci_core_instance.bastion[0].public_ip
}

output "storage_server_private_ips" {
  value = join(" ", oci_core_instance.storage_server.*.private_ip)
}

output "metadata_server_private_ips" {
  value = join(" ", oci_core_instance.metadata_server.*.private_ip)
}

output "management_server_private_ips" {
  value = join(" ", oci_core_instance.management_server.*.private_ip)
}

output "compute_private_ips" {
  value = join(" ", oci_core_instance.client_node.*.private_ip)
}



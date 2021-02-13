
resource "oci_core_vnic_attachment" "storage_server_secondary_vnic_attachment" {
  count = var.storage_server_node_count

  #Required
  create_vnic_details {
    #Required
    subnet_id = local.fs_subnet_id

    #Optional
    assign_public_ip = "false"
    display_name     = "${local.storage_server_filesystem_vnic_hostname_prefix}${format("%01d", count.index + 1)}"
    hostname_label   = "${local.storage_server_filesystem_vnic_hostname_prefix}${format("%01d", count.index + 1)}"

    # false is default value
    skip_source_dest_check = "false"
  }
  instance_id = element(concat(oci_core_instance.storage_server.*.id, [""]), count.index)

  # set to 1, if you want to use 2nd physical NIC for this VNIC
  nic_index = (local.storage_server_dual_nics ? (local.storage_server_hpc_shape ? "0" : "1") : "0")
}

resource "oci_core_vnic_attachment" "metadata_server_secondary_vnic_attachment" {
  count = local.derived_metadata_server_node_count

  #Required
  create_vnic_details {
    #Required
    subnet_id = local.fs_subnet_id

    #Optional
    assign_public_ip = "false"
    display_name     = "${local.metadata_server_filesystem_vnic_hostname_prefix}${format("%01d", count.index + 1)}"
    hostname_label   = "${local.metadata_server_filesystem_vnic_hostname_prefix}${format("%01d", count.index + 1)}"

    # false is default value
    skip_source_dest_check = "false"
  }
  instance_id = element(concat(oci_core_instance.metadata_server.*.id, [""]), count.index)

  # set to 1, if you want to use 2nd physical NIC for this VNIC
  nic_index = (local.metadata_server_dual_nics ? (local.metadata_server_hpc_shape ? "0" : "1") : "0")
}



resource "oci_core_vnic_attachment" "management_server_secondary_vnic_attachment" {
  count = local.derived_management_server_node_count

  #Required
  create_vnic_details {
    #Required
    subnet_id = local.fs_subnet_id

    #Optional
    assign_public_ip = "false"
    display_name     = "${local.management_server_filesystem_vnic_hostname_prefix}${format("%01d", count.index + 1)}"
    hostname_label   = "${local.management_server_filesystem_vnic_hostname_prefix}${format("%01d", count.index + 1)}"

    # false is default value
    skip_source_dest_check = "false"
  }
  instance_id = element(concat(oci_core_instance.management_server.*.id, [""]), count.index)

  # set to 1, if you want to use 2nd physical NIC for this VNIC
  nic_index = (local.management_server_dual_nics ? (local.management_server_hpc_shape ? "0" : "1") : "0")
}

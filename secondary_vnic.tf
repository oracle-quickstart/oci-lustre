resource "oci_core_vnic_attachment" "mds_secondary_vnic_attachment" {
  count = var.lustre_mds_count

  #Required
  create_vnic_details {
    #Required
    subnet_id = oci_core_subnet.publicb[0].id

    #Optional
    assign_public_ip = "false"
    display_name     = "${var.mgs_hostname_prefix_nic1}${format("%01d", count.index + 1)}"
    hostname_label   = "${var.mgs_hostname_prefix_nic1}${format("%01d", count.index + 1)}"

    # false is default value
    skip_source_dest_check = "false"
  }
  instance_id = element(oci_core_instance.lustre_mds.*.id, count.index)

  #Optional
  #display_name = "SecondaryVNIC"
  # set to 1, if you want to use 2nd physical NIC for this VNIC
  nic_index = (local.mds_dual_nics ? "1" : "0")
}

resource "oci_core_vnic_attachment" "oss_secondary_vnic_attachment" {
  count = var.lustre_oss_count
  #count = var.lustre_oss_count

  #Required
  create_vnic_details {
    #Required
    subnet_id = oci_core_subnet.publicb[0].id

    #Optional
    assign_public_ip = "false"
    display_name     = "${var.oss_hostname_prefix_nic1}${format("%01d", count.index + 1)}"
    hostname_label   = "${var.oss_hostname_prefix_nic1}${format("%01d", count.index + 1)}"

    # false is default value
    skip_source_dest_check = "false"
  }
  instance_id = element(oci_core_instance.lustre_oss.*.id, count.index)

  #Optional
  #display_name = "SecondaryVNIC"
  # set to 1, if you want to use 2nd physical NIC for this VNIC
  nic_index = (local.oss_dual_nics ? "1" : "0")
}


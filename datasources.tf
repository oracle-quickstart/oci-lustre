## Copyright © 2021, Oracle and/or its affiliates. 
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

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

data "oci_identity_availability_domains" "availability_domains" {
  compartment_id = var.compartment_ocid
}


data "oci_identity_region_subscriptions" "home_region_subscriptions" {
  tenancy_id = var.tenancy_ocid

  filter {
    name   = "is_home_region"
    values = [true]
  }
}


# Get the latest Oracle Linux image
data "oci_core_images" "ManagementServerImageOCID" {
  compartment_id           = var.compartment_ocid
  operating_system         = var.instance_os
  operating_system_version = var.linux_os_version
  shape                    = var.management_server_shape

  filter {
    name   = "display_name"
    values = ["^.*CentOS[^G]*$"]
    regex  = true
  }
}

data "oci_core_images" "PersistentMetadataServerImageOCID" {
  compartment_id           = var.compartment_ocid
  operating_system         = var.instance_os
  operating_system_version = var.linux_os_version
  shape                    = local.derived_metadata_server_shape

  filter {
    name   = "display_name"
    values = ["^.*CentOS[^G]*$"]
    regex  = true
  }
}

data "oci_core_images" "PersistentStorageServerImageOCID" {
  compartment_id           = var.compartment_ocid
  operating_system         = var.instance_os
  operating_system_version = var.linux_os_version
  shape                    = local.derived_storage_server_shape

  filter {
    name   = "display_name"
    values = ["^.*CentOS[^G]*$"]
    regex  = true
  }
}


data "oci_core_images" "ClientImageOCID" {
  compartment_id           = var.compartment_ocid
  operating_system         = var.instance_os
  operating_system_version = var.linux_os_version
  shape                    = var.client_node_shape

  filter {
    name   = "display_name"
    values = ["^.*CentOS[^G]*$"]
    regex  = true
  }
}

data "oci_core_images" "BastionImageOCID" {
  compartment_id           = var.compartment_ocid
  operating_system         = var.instance_os
  operating_system_version = var.linux_os_version
  shape                    = var.bastion_shape

  filter {
    name   = "display_name"
    values = ["^.*CentOS[^G]*$"]
    regex  = true
  }
}



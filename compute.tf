## Copyright © 2021, Oracle and/or its affiliates. 
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

resource "tls_private_key" "ssh" {
  algorithm = "RSA"
}


locals {
  bastion_subnet_id                   = var.use_existing_vcn ? var.bastion_subnet_id : element(concat(oci_core_subnet.public.*.id, [""]), 0)
  bastion_image_id                    = (var.use_marketplace_image ? var.mp_listing_resource_id : lookup(data.oci_core_images.BastionImageOCID.images[0], "id"))
  management_server_image_id          = (var.use_marketplace_image ? var.mp_listing_resource_id : lookup(data.oci_core_images.ManagementServerImageOCID.images[0], "id"))
  persistent_metadata_server_image_id = (var.use_marketplace_image ? var.mp_listing_resource_id : lookup(data.oci_core_images.PersistentMetadataServerImageOCID.images[0], "id"))
  persistent_storage_server_image_id  = (var.use_marketplace_image ? var.mp_listing_resource_id : lookup(data.oci_core_images.PersistentStorageServerImageOCID.images[0], "id"))
  client_image_id                     = (var.use_marketplace_image ? var.mp_listing_resource_id : lookup(data.oci_core_images.ClientImageOCID.images[0], "id"))
  client_subnet_id                    = var.use_existing_vcn ? var.fs_subnet_id : element(concat(oci_core_subnet.fs.*.id, [""]), 0)
}

data "template_file" "bastion_config" {
  template = file("${path.module}/config.bastion")
  vars = {
    key = tls_private_key.ssh.private_key_pem
  }
}

# Dictionary Locals
locals {
  compute_flexible_shapes = [
    "VM.Standard.E3.Flex",
    "VM.Standard.E4.Flex",
    "VM.Optimized3.Flex"
  ]
}

# Checks if is using Flexible Compute Shapes
locals {
  is_flexible_bastion_shape                    = contains(local.compute_flexible_shapes, var.bastion_shape)
  is_flexible_management_server_shape          = contains(local.compute_flexible_shapes, var.management_server_shape)
  is_flexible_persistent_metadata_server_shape = contains(local.compute_flexible_shapes, local.derived_metadata_server_shape)
  is_flexible_persistent_storage_server_shape  = contains(local.compute_flexible_shapes, local.derived_storage_server_shape)
  is_flexible_client_node_shape_shape          = contains(local.compute_flexible_shapes, var.client_node_shape)
}

resource "oci_core_instance" "bastion" {
  depends_on = [oci_core_instance.storage_server, oci_core_instance.metadata_server, oci_core_instance.management_server, oci_core_subnet.public,
  ]
  count               = var.bastion_node_count
  availability_domain = local.ad
  #fault_domain        = "FAULT-DOMAIN-${(count.index%3)+1}"
  compartment_id = var.compartment_ocid
  shape          = var.bastion_shape

  dynamic "shape_config" {
    for_each = local.is_flexible_bastion_shape ? [1] : []
    content {
      memory_in_gbs = var.bastion_flex_shape_mem
      ocpus         = var.bastion_flex_shape_ocpus
    }
  }

  display_name = "${var.bastion_hostname_prefix}${format("%01d", count.index + 1)}"

  metadata = {
    ssh_authorized_keys = tls_private_key.ssh.public_key_openssh
    user_data           = base64encode(data.template_file.bastion_config.rendered)
  }

  source_details {
    source_type = "image"
    source_id   = local.bastion_image_id
  }


  agent_config {
    is_management_disabled = true
  }

  create_vnic_details {
    subnet_id      = local.bastion_subnet_id
    hostname_label = "${var.bastion_hostname_prefix}${format("%01d", count.index + 1)}"
  }

  #launch_options {
  # network_type = "VFIO"
  #}

  defined_tags = { "${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }


  provisioner "file" {
    source      = "${path.module}/playbooks"
    destination = "/home/opc/"
    connection {
      host        = oci_core_instance.bastion[0].public_ip
      type        = "ssh"
      user        = "opc"
      private_key = tls_private_key.ssh.private_key_pem
    }
  }

  provisioner "file" {
    content = templatefile("${path.module}/inventory.tpl", {
      bastion_name                                      = oci_core_instance.bastion[0].display_name,
      bastion_ip                                        = oci_core_instance.bastion[0].private_ip,
      storage                                           = zipmap(data.oci_core_instance.storage_server.*.display_name, data.oci_core_instance.storage_server.*.private_ip),
      metadata                                          = zipmap(data.oci_core_instance.metadata_server.*.display_name, data.oci_core_instance.metadata_server.*.private_ip),
      management                                        = zipmap(data.oci_core_instance.management_server.*.display_name, data.oci_core_instance.management_server.*.private_ip),
      compute                                           = zipmap(data.oci_core_instance.client_node.*.display_name, data.oci_core_instance.client_node.*.private_ip),
      fs_name                                           = var.fs_name,
      fs_type                                           = var.fs_type,
      vcn_domain_name                                   = local.vcn_domain_name,
      public_subnet                                     = data.oci_core_subnet.public_subnet.cidr_block,
      private_storage_subnet_dns_label                  = data.oci_core_subnet.private_storage_subnet.dns_label,
      private_fs_subnet_dns_label                       = data.oci_core_subnet.private_fs_subnet.dns_label,
      filesystem_subnet_domain_name                     = local.filesystem_subnet_domain_name,
      storage_subnet_domain_name                        = local.storage_subnet_domain_name,
      management_server_filesystem_vnic_hostname_prefix = local.management_server_filesystem_vnic_hostname_prefix,
      metadata_server_filesystem_vnic_hostname_prefix   = local.metadata_server_filesystem_vnic_hostname_prefix
      derived_management_server_disk_count              = local.derived_management_server_disk_count,
      derived_management_server_node_count              = local.derived_management_server_node_count,
      storage_server_node_count                         = var.storage_server_node_count,
      derived_metadata_server_disk_count                = local.derived_metadata_server_disk_count,
      derived_metadata_server_node_count                = local.derived_metadata_server_node_count,
      storage_tier_1_disk_perf_tier                     = var.storage_tier_1_disk_perf_tier,
      stripe_size                                       = var.stripe_size,
      mount_point                                       = var.mount_point,
      storage_server_filesystem_vnic_hostname_prefix    = local.storage_server_filesystem_vnic_hostname_prefix,
    })

    destination = "/home/opc/playbooks/inventory"
    connection {
      host        = oci_core_instance.bastion[0].public_ip
      type        = "ssh"
      user        = "opc"
      private_key = tls_private_key.ssh.private_key_pem
    }
  }


  provisioner "file" {
    content     = tls_private_key.ssh.private_key_pem
    destination = "/home/opc/.ssh/cluster.key"
    connection {
      host        = oci_core_instance.bastion[0].public_ip
      type        = "ssh"
      user        = "opc"
      private_key = tls_private_key.ssh.private_key_pem
    }
  }

  provisioner "file" {
    content     = tls_private_key.ssh.private_key_pem
    destination = "/home/opc/.ssh/id_rsa"
    connection {
      host        = oci_core_instance.bastion[0].public_ip
      type        = "ssh"
      user        = "opc"
      private_key = tls_private_key.ssh.private_key_pem
    }
  }

  provisioner "file" {
    content     = join("\n", data.oci_core_instance.storage_server.*.private_ip)
    destination = "/tmp/hosts"
    connection {
      host        = oci_core_instance.bastion[0].public_ip
      type        = "ssh"
      user        = "opc"
      private_key = tls_private_key.ssh.private_key_pem
    }
  }


  provisioner "file" {
    source      = "${path.module}/configure.sh"
    destination = "/tmp/configure.sh"
    connection {
      host        = oci_core_instance.bastion[0].public_ip
      type        = "ssh"
      user        = "opc"
      private_key = tls_private_key.ssh.private_key_pem
    }
  }


}

resource "null_resource" "run_configure_sh" {
  depends_on = [oci_core_instance.bastion, null_resource.notify_management_server_nodes_block_attach_complete, null_resource.notify_metadata_server_nodes_block_attach_complete, null_resource.notify_storage_server_nodes_block_attach_complete]
  count      = var.bastion_node_count


  provisioner "file" {
    source      = "${path.module}/configure.sh"
    destination = "/tmp/configure.sh"
    connection {
      host        = oci_core_instance.bastion[0].public_ip
      type        = "ssh"
      user        = "opc"
      private_key = tls_private_key.ssh.private_key_pem
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod 600 /home/opc/.ssh/cluster.key",
      "chmod 600 /home/opc/.ssh/id_rsa",
      "chmod a+x /tmp/configure.sh",
      "chmod a+x /tmp/*.sh",
      "/tmp/configure.sh"
    ]
    connection {
      host        = oci_core_instance.bastion[0].public_ip
      type        = "ssh"
      user        = "opc"
      private_key = tls_private_key.ssh.private_key_pem
    }
  }
}

locals {
  storage_subnet_id                 = var.use_existing_vcn ? var.storage_subnet_id : element(concat(oci_core_subnet.storage.*.id, [""]), 0)
  fs_subnet_id                      = var.use_existing_vcn ? var.fs_subnet_id : element(concat(oci_core_subnet.fs.*.id, [""]), 0)
  derived_storage_server_shape      = (length(regexall("^Scratch", var.fs_type)) > 0 ? var.scratch_storage_server_shape : var.persistent_storage_server_shape)
  derived_storage_server_disk_count = (length(regexall("DenseIO", local.derived_storage_server_shape)) > 0 ? 0 : var.storage_tier_1_disk_count)
  derived_metadata_server_shape     = (length(regexall("^Scratch", var.fs_type)) > 0 ? var.scratch_metadata_server_shape : var.persistent_metadata_server_shape)
}

locals {
  # The below 2 lines are there to use common variable in rest of the TF & bash code which works across deployment of FS like Lustre, BeeGFS, Gluster.  So do not change. 
  derived_management_server_node_count = (var.management_server_node_count)
  derived_metadata_server_node_count   = (var.metadata_server_node_count)
  derived_management_server_disk_count = (length(regexall("DenseIO", var.management_server_shape)) > 0 ? 0 : var.management_server_disk_count)
  derived_metadata_server_disk_count   = (length(regexall("DenseIO", local.derived_metadata_server_shape)) > 0 ? 0 : var.metadata_server_disk_count)
}

resource "oci_core_instance" "storage_server" {
  count               = var.storage_server_node_count
  availability_domain = local.ad

  #fault_domain        = "FAULT-DOMAIN-${(count.index%3)+1}"
  compartment_id = var.compartment_ocid
  display_name   = "${var.storage_server_hostname_prefix}${format("%01d", count.index + 1)}"
  shape          = local.derived_storage_server_shape

  dynamic "shape_config" {
    for_each = local.is_flexible_persistent_storage_server_shape ? [1] : []
    content {
      memory_in_gbs = var.persistent_storage_server_flex_shape_mem
      ocpus         = var.persistent_storage_server_flex_shape_ocpus
    }
  }

  create_vnic_details {
    subnet_id        = local.storage_subnet_id
    assign_public_ip = false
    hostname_label   = "${var.storage_server_hostname_prefix}${format("%01d", count.index + 1)}"
  }

  source_details {
    source_type = "image"
    source_id   = local.persistent_storage_server_image_id
  }
  agent_config {
    is_management_disabled = true
  }

  launch_options {
    network_type = "VFIO"
  }

  metadata = {
    ssh_authorized_keys = join(
      "\n",
      [
        tls_private_key.ssh.public_key_openssh
      ]
    )
    user_data = base64encode(join("\n", tolist([
      "#!/usr/bin/env bash",
      "set -x",
    ])))
  }

  defined_tags = { "${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }

  timeouts {
    create = "120m"
  }

}

resource "oci_core_instance" "metadata_server" {
  count               = local.derived_metadata_server_node_count
  availability_domain = local.ad
  #fault_domain        = "FAULT-DOMAIN-${(count.index%3)+1}"
  compartment_id = var.compartment_ocid
  display_name   = "${var.metadata_server_hostname_prefix}${format("%01d", count.index + 1)}"
  shape          = local.derived_metadata_server_shape

  dynamic "shape_config" {
    for_each = local.is_flexible_persistent_metadata_server_shape ? [1] : []
    content {
      memory_in_gbs = var.persistent_metadata_server_flex_shape_mem
      ocpus         = var.persistent_metadata_server_flex_shape_ocpus
    }
  }

  create_vnic_details {
    subnet_id        = local.storage_subnet_id
    assign_public_ip = false
    hostname_label   = "${var.metadata_server_hostname_prefix}${format("%01d", count.index + 1)}"
  }

  source_details {
    source_type = "image"
    source_id   = local.persistent_metadata_server_image_id
  }
  agent_config {
    is_management_disabled = true
  }

  launch_options {
    network_type = "VFIO"
  }

  metadata = {
    ssh_authorized_keys = join(
      "\n",
      [
        tls_private_key.ssh.public_key_openssh
      ]
    )
    user_data = base64encode(join("\n", tolist([
      "#!/usr/bin/env bash",
      "set -x",
    ])))
  }

  defined_tags = { "${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }

  timeouts {
    create = "120m"
  }

}

resource "oci_core_instance" "management_server" {
  count               = local.derived_management_server_node_count
  availability_domain = local.ad
  #fault_domain        = "FAULT-DOMAIN-${(count.index%3)+1}"
  compartment_id = var.compartment_ocid
  display_name   = "${var.management_server_hostname_prefix}${format("%01d", count.index + 1)}"
  shape          = var.management_server_shape

  dynamic "shape_config" {
    for_each = local.is_flexible_management_server_shape ? [1] : []
    content {
      memory_in_gbs = var.management_server_flex_shape_mem
      ocpus         = var.management_server_flex_shape_ocpus
    }
  }

  create_vnic_details {
    subnet_id        = local.storage_subnet_id
    assign_public_ip = false
    hostname_label   = "${var.management_server_hostname_prefix}${format("%01d", count.index + 1)}"
  }

  source_details {
    source_type = "image"
    source_id   = local.management_server_image_id
  }

  agent_config {
    is_management_disabled = true
  }
  # }
  #launch_options {
  #   network_type = "VFIO"
  # }

  metadata = {
    ssh_authorized_keys = join(
      "\n",
      [
        tls_private_key.ssh.public_key_openssh
      ]
    )
    user_data = base64encode(join("\n", tolist([
      "#!/usr/bin/env bash",
      "set -x",
    ])))
  }

  defined_tags = { "${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }

  timeouts {
    create = "120m"
  }


}


resource "oci_core_instance" "client_node" {
  count               = var.client_node_count
  availability_domain = local.ad
  #fault_domain        = "FAULT-DOMAIN-${(count.index%3)+1}"
  compartment_id = var.compartment_ocid
  display_name   = "${var.client_node_hostname_prefix}${format("%01d", count.index + 1)}"
  shape          = var.client_node_shape

  dynamic "shape_config" {
    for_each = local.is_flexible_client_node_shape_shape ? [1] : []
    content {
      memory_in_gbs = var.client_node_flex_shape_mem
      ocpus         = var.client_node_flex_shape_ocpus
    }
  }
  create_vnic_details {
    subnet_id        = local.client_subnet_id
    assign_public_ip = false
    hostname_label   = "${var.client_node_hostname_prefix}${format("%01d", count.index + 1)}"
  }

  source_details {
    source_type = "image"
    source_id   = local.client_image_id
  }
  agent_config {
    is_management_disabled = true
  }

  launch_options {
    network_type = "VFIO"
  }

  metadata = {
    ssh_authorized_keys = join(
      "\n",
      [
        tls_private_key.ssh.public_key_openssh
      ]
    )
    user_data = base64encode(join("\n", tolist([
      "#!/usr/bin/env bash",
      "set -x",
    ])))
  }

  defined_tags = { "${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }

  timeouts {
    create = "120m"
  }

}



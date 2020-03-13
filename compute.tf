resource "tls_private_key" "public_private_key_pair" {
  algorithm   = "RSA"
}

#######
# Note:  MGS is deployed on first instance of MDS server
######

resource "oci_core_instance" "lustre_mds" {
  count               = var.lustre_mds_count
  #availability_domain = data.oci_identity_availability_domains.ADs.availability_domains[var.AD - 1]["name"]
  availability_domain = local.ad
  compartment_id      = var.compartment_ocid
  display_name        = "${var.mds_hostname_prefix_nic0}${format("%01d", count.index + 1)}"
  hostname_label      = "${var.mds_hostname_prefix_nic0}${format("%01d", count.index + 1)}"
  shape               = var.lustre_mds_server_shape
  subnet_id           = oci_core_subnet.public[0].id

  source_details {
    source_type = "image"
    source_id   = (var.use_marketplace_image ? var.mp_listing_resource_id : var.images[var.region])
    #boot_volume_size_in_gbs = "${var.boot_volume_size}"
  }

  launch_options {
    network_type = "VFIO"
  }

  metadata = {
    ssh_authorized_keys = join(
      "\n",
      [
        var.ssh_public_key,
        tls_private_key.public_private_key_pair.public_key_openssh
      ]
    )
    user_data = base64encode(
      join(
        "\n",
        [
          "#!/usr/bin/env bash",
          "mds_dual_nics=\"${local.mds_dual_nics}\"",
          "oss_dual_nics=\"${local.oss_dual_nics}\"",
          "mgs_hostname_prefix_nic0=${var.mgs_hostname_prefix_nic0}",
          "mgs_hostname_prefix_nic1=${var.mgs_hostname_prefix_nic1}",
          "PublicSubnetsFQDN=\"${oci_core_virtual_network.lustre.dns_label}.oraclevcn.com ${oci_core_subnet.public[0].dns_label}.${oci_core_virtual_network.lustre.dns_label}.oraclevcn.com\"",
          "PublicBSubnetsFQDN=\"${oci_core_virtual_network.lustre.dns_label}.oraclevcn.com ${oci_core_subnet.publicb[0].dns_label}.${oci_core_virtual_network.lustre.dns_label}.oraclevcn.com\"",
          file("${var.scripts_directory}/lustre_mds.sh"),
        ],
      ),
    )
  }

  timeouts {
    create = "60m"
  }
}

resource "oci_core_instance" "lustre_oss" {
  count               = var.lustre_oss_count
  #availability_domain = data.oci_identity_availability_domains.ADs.availability_domains[var.AD - 1]["name"]
  availability_domain = local.ad
  compartment_id      = var.compartment_ocid
  display_name        = "${var.oss_hostname_prefix_nic0}${format("%01d", count.index + 1)}"
  hostname_label      = "${var.oss_hostname_prefix_nic0}${format("%01d", count.index + 1)}"
  shape               = var.lustre_oss_server_shape
  subnet_id           = oci_core_subnet.public[0].id

  source_details {
    source_type = "image"
    source_id   = (var.use_marketplace_image ? var.mp_listing_resource_id : var.images[var.region])
    #boot_volume_size_in_gbs = "${var.boot_volume_size}"
  }

  launch_options {
    network_type = "VFIO"
  }

  metadata = {
    ssh_authorized_keys = join(
      "\n",
      [
        var.ssh_public_key,
        tls_private_key.public_private_key_pair.public_key_openssh
      ]
    )
    user_data = base64encode(
      join(
        "\n",
        [
          "#!/usr/bin/env bash",
          "mds_dual_nics=\"${local.mds_dual_nics}\"",
          "oss_dual_nics=\"${local.oss_dual_nics}\"",
          "mgs_hostname_prefix_nic0=${var.mgs_hostname_prefix_nic0}",
          "mgs_hostname_prefix_nic1=${var.mgs_hostname_prefix_nic1}",
          "PublicSubnetsFQDN=\"${oci_core_virtual_network.lustre.dns_label}.oraclevcn.com ${oci_core_subnet.public[0].dns_label}.${oci_core_virtual_network.lustre.dns_label}.oraclevcn.com\"",
          "PublicBSubnetsFQDN=\"${oci_core_virtual_network.lustre.dns_label}.oraclevcn.com ${oci_core_subnet.publicb[0].dns_label}.${oci_core_virtual_network.lustre.dns_label}.oraclevcn.com\"",
          file("${var.scripts_directory}/lustre.sh"),
        ],
      ),
    )
  }

  timeouts {
    create = "60m"
  }
}

resource "oci_core_instance" "lustre_client" {
  count               = var.lustre_client_count
  #availability_domain = data.oci_identity_availability_domains.ADs.availability_domains[var.AD - 1]["name"]
  availability_domain = local.ad
  compartment_id      = var.compartment_ocid
  display_name        = "${var.lustre_client_hostname_prefix}${format("%01d", count.index + 1)}"
  hostname_label      = "${var.lustre_client_hostname_prefix}${format("%01d", count.index + 1)}"
  shape               = var.lustre_client_shape
  subnet_id           = oci_core_subnet.publicb[0].id

  source_details {
    source_type = "image"
    source_id   = (var.use_marketplace_image ? var.mp_listing_resource_id : var.images[var.region])
    #boot_volume_size_in_gbs = "${var.boot_volume_size}"
  }

  launch_options {
    network_type = "VFIO"
  }

  metadata = {
    ssh_authorized_keys = join(
      "\n",
      [
        var.ssh_public_key,
        tls_private_key.public_private_key_pair.public_key_openssh
      ]
    )
    user_data = base64encode(
      join(
        "\n",
        [
          "#!/usr/bin/env bash",
          "mds_dual_nics=\"${local.mds_dual_nics}\"",
          "oss_dual_nics=\"${local.oss_dual_nics}\"",
          "mgs_hostname_prefix_nic0=${var.mgs_hostname_prefix_nic0}",
          "mgs_hostname_prefix_nic1=${var.mgs_hostname_prefix_nic1}",
          file("${var.scripts_directory}/lustre_client.sh"),
        ],
      ),
    )

  }

  timeouts {
    create = "60m"
  }
}

/* bastion instances */

resource "oci_core_instance" "bastion" {
  count               = var.bastion_node_count
  #availability_domain = data.oci_identity_availability_domains.ADs.availability_domains[var.AD - 1]["name"]
  availability_domain = local.ad
  compartment_id      = var.compartment_ocid
  display_name        = "${var.bastion_hostname_prefix}${format("%01d", count.index+1)}"
  shape               = var.bastion_shape
  hostname_label      = "${var.bastion_hostname_prefix}${format("%01d", count.index+1)}"

  create_vnic_details {
    subnet_id              = oci_core_subnet.public[0].id
    skip_source_dest_check = true
  }

  metadata = {
    ssh_authorized_keys = join(
      "\n",
      [
        var.ssh_public_key,
        tls_private_key.public_private_key_pair.public_key_openssh
      ]
    )
  }

  source_details {
    source_type = "image"
    source_id   = (var.use_marketplace_image ? var.mp_listing_resource_id : var.images[var.region])
  }
}

/*
Resource to check if the user_data/cloud-init script was successfully completed.
*/
resource "null_resource" "lustre-mds-setup-after-kernel-update" {
  depends_on = [
    oci_core_instance.lustre_mds,
    oci_core_volume.lustre_mds_blockvolume,
    oci_core_volume_attachment.mds_blockvolume_attach,
  ]
  count = var.lustre_mds_count
  triggers = {
    instance_ids = join(",", oci_core_instance.lustre_mds.*.id)
  }

/*
  provisioner "file" {
    source      = var.ssh_private_key_path
    destination = "/home/${var.ssh_user}/.ssh/id_rsa"
    connection {
      agent               = false
      timeout             = "30m"
      host                = element(oci_core_instance.lustre_mds.*.private_ip, count.index)
      user                = var.ssh_user
      private_key         = tls_private_key.public_private_key_pair.private_key_pem
      bastion_host        = oci_core_instance.bastion[0].public_ip
      bastion_port        = "22"
      bastion_user        = var.ssh_user
      bastion_private_key = tls_private_key.public_private_key_pair.private_key_pem
    }
  }
*/

  provisioner "file" {

    source      = "${var.scripts_directory}/"
    destination = "/tmp/"
    connection {
      agent               = false
      timeout             = "30m"
      host                = element(oci_core_instance.lustre_mds.*.private_ip, count.index)
      user                = var.ssh_user
      private_key         = tls_private_key.public_private_key_pair.private_key_pem
      bastion_host        = oci_core_instance.bastion[0].public_ip
      bastion_port        = "22"
      bastion_user        = var.ssh_user
      bastion_private_key = tls_private_key.public_private_key_pair.private_key_pem
    }
  }

  provisioner "remote-exec" {
    connection {
      agent               = false
      timeout             = "30m"
      host                = element(oci_core_instance.lustre_mds.*.private_ip, count.index)
      user                = var.ssh_user
      private_key         = tls_private_key.public_private_key_pair.private_key_pem
      bastion_host        = oci_core_instance.bastion[0].public_ip
      bastion_port        = "22"
      bastion_user        = var.ssh_user
      bastion_private_key = tls_private_key.public_private_key_pair.private_key_pem
    }
    inline = [
      "set -x",
      "echo about to run /tmp/nodes-cloud-init-complete-status-check.sh",
      "sudo -s bash -c 'set -x && chmod 777 /tmp/*.sh'",
      "sudo -s bash -c 'set -x && /tmp/nodes-cloud-init-complete-status-check.sh'",
      "sudo -s bash -c 'set -x && /tmp/os_perf_tuning.sh'",
      "sudo -s bash -c 'set -x && /tmp/kernel_parameters_tuning.sh'",
      "sudo -s bash -c 'set -x && /tmp/nic_tuning.sh'",
      "sudo -s bash -c \"set -x && /tmp/mds_setup.sh ${var.enable_mdt_raid0} ${var.mgs_hostname_nic0}.${oci_core_subnet.public[0].dns_label}.${oci_core_virtual_network.lustre.dns_label}.oraclevcn.com ${var.mgs_hostname_nic1}.${oci_core_subnet.publicb[0].dns_label}.${oci_core_virtual_network.lustre.dns_label}.oraclevcn.com \"",
      #"sudo -s bash -c 'set -x && /tmp/lustre_all_tuning.sh'",
      "sudo -s bash -c 'set -x && /tmp/lustre_server_tuning.sh'",
    ]
  }
}

/*
Resource to check if the user_data/cloud-init script was successfully completed.
*/
resource "null_resource" "lustre-oss-setup-after-kernel-update" {
  depends_on = [
    oci_core_instance.lustre_oss,
    oci_core_volume.lustre_oss_blockvolume,
    oci_core_volume_attachment.blockvolume_attach,
    null_resource.lustre-mds-setup-after-kernel-update,
  ]
  count = var.lustre_oss_count
  triggers = {
    instance_ids = join(",", oci_core_instance.lustre_oss.*.id)
  }

/*
  provisioner "file" {
    source      = var.ssh_private_key_path
    destination = "/home/${var.ssh_user}/.ssh/id_rsa"
    connection {
      agent               = false
      timeout             = "30m"
      host                = element(oci_core_instance.lustre_oss.*.private_ip, count.index)
      user                = var.ssh_user
      private_key         = tls_private_key.public_private_key_pair.private_key_pem
      bastion_host        = oci_core_instance.bastion[0].public_ip
      bastion_port        = "22"
      bastion_user        = var.ssh_user
      bastion_private_key = tls_private_key.public_private_key_pair.private_key_pem
    }
  }
*/

  provisioner "file" {
    source      = "${var.scripts_directory}/"
    destination = "/tmp/"
    connection {
      agent               = false
      timeout             = "30m"
      host                = element(oci_core_instance.lustre_oss.*.private_ip, count.index)
      user                = var.ssh_user
      private_key         = tls_private_key.public_private_key_pair.private_key_pem
      bastion_host        = oci_core_instance.bastion[0].public_ip
      bastion_port        = "22"
      bastion_user        = var.ssh_user
      bastion_private_key = tls_private_key.public_private_key_pair.private_key_pem
    }
  }

  provisioner "remote-exec" {
    connection {
      agent               = false
      timeout             = "30m"
      host                = element(oci_core_instance.lustre_oss.*.private_ip, count.index)
      user                = var.ssh_user
      private_key         = tls_private_key.public_private_key_pair.private_key_pem
      bastion_host        = oci_core_instance.bastion[0].public_ip
      bastion_port        = "22"
      bastion_user        = var.ssh_user
      bastion_private_key = tls_private_key.public_private_key_pair.private_key_pem
    }
    inline = [
      "set -x",
      "echo about to run /tmp/nodes-cloud-init-complete-status-check.sh",
      "sudo -s bash -c 'set -x && chmod 777 /tmp/*.sh'",
      "sudo -s bash -c 'set -x && /tmp/nodes-cloud-init-complete-status-check.sh'",
      "sudo -s bash -c 'set -x && /tmp/os_perf_tuning.sh'",
      "sudo -s bash -c 'set -x && /tmp/kernel_parameters_tuning.sh'",
      "sudo -s bash -c 'set -x && /tmp/nic_tuning.sh'",
      "sudo -s bash -c \"set -x && /tmp/oss_setup.sh ${var.enable_ost_raid0}  ${var.mgs_hostname_nic0}.${oci_core_subnet.public[0].dns_label}.${oci_core_virtual_network.lustre.dns_label}.oraclevcn.com ${var.mgs_hostname_nic1}.${oci_core_subnet.publicb[0].dns_label}.${oci_core_virtual_network.lustre.dns_label}.oraclevcn.com \"",
      #"sudo -s bash -c 'set -x && /tmp/lustre_all_tuning.sh'",
      "sudo -s bash -c 'set -x && /tmp/lustre_server_tuning.sh'",
      "sudo -s bash -c 'set -x && /tmp/lustre_oss_tuning.sh'",
    ]
  }
}

/*
Resource to check if the user_data/cloud-init script was successfully completed.
*/
resource "null_resource" "lustre-client-setup-after-kernel-update" {
  depends_on = [
    oci_core_instance.lustre_client,
    null_resource.lustre-oss-setup-after-kernel-update,
    null_resource.lustre-mds-setup-after-kernel-update,
  ]
  count = var.lustre_client_count
  triggers = {
    instance_ids = join(",", oci_core_instance.lustre_client.*.id)
  }

/*
  provisioner "file" {
    source      = var.ssh_private_key_path
    destination = "/home/${var.ssh_user}/.ssh/id_rsa"
    connection {
      agent               = false
      timeout             = "30m"
      host                = element(oci_core_instance.lustre_client.*.private_ip, count.index)
      user                = var.ssh_user
      private_key         = tls_private_key.public_private_key_pair.private_key_pem
      bastion_host        = oci_core_instance.bastion[0].public_ip
      bastion_port        = "22"
      bastion_user        = var.ssh_user
      bastion_private_key = tls_private_key.public_private_key_pair.private_key_pem
    }
  }
*/

  provisioner "file" {
    source      = "${var.scripts_directory}/"
    destination = "/tmp/"
    connection {
      agent               = false
      timeout             = "30m"
      host                = element(oci_core_instance.lustre_client.*.private_ip, count.index)
      user                = var.ssh_user
      private_key         = tls_private_key.public_private_key_pair.private_key_pem
      bastion_host        = oci_core_instance.bastion[0].public_ip
      bastion_port        = "22"
      bastion_user        = var.ssh_user
      bastion_private_key = tls_private_key.public_private_key_pair.private_key_pem
    }
  }

  provisioner "remote-exec" {
    connection {
      agent               = false
      timeout             = "30m"
      host                = element(oci_core_instance.lustre_client.*.private_ip, count.index)
      user                = var.ssh_user
      private_key         = tls_private_key.public_private_key_pair.private_key_pem
      bastion_host        = oci_core_instance.bastion[0].public_ip
      bastion_port        = "22"
      bastion_user        = var.ssh_user
      bastion_private_key = tls_private_key.public_private_key_pair.private_key_pem
    }
    inline = [
      "set -x",
      "echo about to run /tmp/nodes-cloud-init-complete-status-check.sh",
      "sudo -s bash -c 'set -x && chmod 777 /tmp/*.sh'",
      "sudo -s bash -c 'set -x && /tmp/nodes-cloud-init-complete-status-check.sh'",
      "sudo -s bash -c 'set -x && /tmp/os_perf_tuning.sh'",
      "sudo -s bash -c 'set -x && /tmp/kernel_parameters_tuning.sh'",
      "sudo -s bash -c 'set -x && /tmp/nic_tuning.sh'",
      "sudo -s bash -c \"set -x && /tmp/client_setup.sh  ${var.mgs_hostname_nic0}.${oci_core_subnet.public[0].dns_label}.${oci_core_virtual_network.lustre.dns_label}.oraclevcn.com ${var.mgs_hostname_nic1}.${oci_core_subnet.publicb[0].dns_label}.${oci_core_virtual_network.lustre.dns_label}.oraclevcn.com  \"",
      #"sudo -s bash -c 'set -x && /tmp/lustre_all_tuning.sh'",
      "sudo -s bash -c 'set -x && /tmp/lustre_client_tuning.sh'",
    ]
  }
}


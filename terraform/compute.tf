resource "oci_core_instance" "lustre_mds" {
  count               = "${var.lustre_mds_count}"
  availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[var.AD - 1],"name")}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "Lustre MDS Server ${format("%01d", count.index+1)}"
  hostname_label      = "Lustre-MDS-Server-${format("%01d", count.index+1)}"
  shape               = "${var.lustre_mds_server_shape}"
  subnet_id           = "${oci_core_subnet.public.*.id[var.AD - 1]}"

  source_details {
    source_type = "image"
    source_id = "${var.InstanceImageOCID[var.region]}"
    #boot_volume_size_in_gbs = "${var.boot_volume_size}"
  }

  metadata {
    ssh_authorized_keys = "${var.ssh_public_key}"
    #user_data = "${base64encode(data.template_file.boot_script.rendered)}"
    #user_data =  "${base64encode(file(../scripts/lustre.sh))}"
    user_data           = "${base64encode(file("../scripts/lustre_mds.sh"))}"
  }

  timeouts {
    create = "60m"
  }

}



resource "oci_core_instance" "lustre_oss" {
  count               = "${var.lustre_oss_count}"
  availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[var.AD - 1],"name")}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "Lustre OSS Server ${format("%01d", count.index+1)}"
  hostname_label      = "Lustre-OSS-Server-${format("%01d", count.index+1)}"
  shape               = "${var.lustre_oss_server_shape}"
  subnet_id           = "${oci_core_subnet.public.*.id[var.AD - 1]}"

  source_details {
    source_type = "image"
    source_id = "${var.InstanceImageOCID[var.region]}"
    #boot_volume_size_in_gbs = "${var.boot_volume_size}"
  }

  metadata {
    ssh_authorized_keys = "${var.ssh_public_key}"
    #user_data = "${base64encode(data.template_file.boot_script.rendered)}"
    #user_data =  "${base64encode(file(../scripts/lustre.sh))}"
    user_data           = "${base64encode(file("../scripts/lustre.sh"))}"
  }

  timeouts {
    create = "60m"
  }

}


resource "oci_core_instance" "lustre_client" {
  count               = "${var.lustre_client_count}"
  availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[var.AD - 1],"name")}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "Lustre Client ${format("%01d", count.index+1)}"
  hostname_label      = "Lustre-Client-${format("%01d", count.index+1)}"
  shape               = "${var.lustre_client_shape}"
  subnet_id           = "${oci_core_subnet.public.*.id[var.AD - 1]}"

  source_details {
    source_type = "image"
    source_id = "${var.InstanceImageOCID[var.region]}"
    #boot_volume_size_in_gbs = "${var.boot_volume_size}"
  }

  metadata {
    ssh_authorized_keys = "${var.ssh_public_key}"
    #user_data = "${base64encode(data.template_file.boot_script.rendered)}"
    #user_data =  "${base64encode(file(../scripts/lustre.sh))}"
    user_data           = "${base64encode(file("../scripts/lustre_client.sh"))}"
  }

  timeouts {
    create = "60m"
  }

}



/* bastion instances */

resource "oci_core_instance" "bastion" {
  count = "${var.bastion_server_count}"
  availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[var.AD - 1],"name")}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "bastion ${format("%01d", count.index+1)}"
  shape               = "${var.bastion_server_shape}"
  hostname_label      = "bastion-${format("%01d", count.index+1)}"

  create_vnic_details {
    subnet_id              = "${oci_core_subnet.public.*.id[var.AD - 1]}"
    skip_source_dest_check = true
  }

  metadata {
    ssh_authorized_keys = "${var.ssh_public_key}"
  }


  source_details {
    source_type = "image"
    source_id   = "${var.InstanceImageOCID[var.region]}"
  }
}



/*
Resource to check if the user_data/cloud-init script was successfully completed.
*/
resource "null_resource" "lustre-mds-setup-after-kernel-update" {
    depends_on = ["oci_core_instance.lustre_mds" , "oci_core_volume.lustre_mds_blockvolume", "oci_core_volume_attachment.mds_blockvolume_attach" ]
    count               = "${var.lustre_mds_count}"
    triggers {
      instance_ids = "${join(",", oci_core_instance.lustre_mds.*.id)}"
    }

    provisioner "file" {
      source = "${var.ssh_private_key_path}"
      destination = "/home/${var.ssh_user}/.ssh/id_rsa"
      connection {
        agent               = false
        timeout             = "30m"
        host                = "${element(oci_core_instance.lustre_mds.*.private_ip, count.index)}"
        user                = "${var.ssh_user}"
        private_key         = "${var.ssh_private_key}"
        bastion_host        = "${oci_core_instance.bastion.*.public_ip[0]}"
        bastion_port        = "22"
        bastion_user        = "${var.ssh_user}"
        bastion_private_key = "${var.ssh_private_key}"
      }
    }

    provisioner "file" {
      source = "../scripts/nodes-cloud-init-complete-status-check.sh"
      destination = "/tmp/nodes-cloud-init-complete-status-check.sh"
      connection {
        agent               = false
        timeout             = "30m"
        host                = "${element(oci_core_instance.lustre_mds.*.private_ip, count.index)}"
        user                = "${var.ssh_user}"
        private_key         = "${var.ssh_private_key}"
        bastion_host        = "${oci_core_instance.bastion.*.public_ip[0]}"
        bastion_port        = "22"
        bastion_user        = "${var.ssh_user}"
        bastion_private_key = "${var.ssh_private_key}"
      }
    }

    provisioner "file" {
      source = "../scripts/mds_setup.sh"
      destination = "/tmp/mds_setup.sh"
      connection {
        agent               = false
        timeout             = "30m"
        host                = "${element(oci_core_instance.lustre_mds.*.private_ip, count.index)}"
        user                = "${var.ssh_user}"
        private_key         = "${var.ssh_private_key}"
        bastion_host        = "${oci_core_instance.bastion.*.public_ip[0]}"
        bastion_port        = "22"
        bastion_user        = "${var.ssh_user}"
        bastion_private_key = "${var.ssh_private_key}"
      }
    }


    provisioner "remote-exec" {
      connection {
        agent               = false
        timeout             = "30m"
        host                = "${element(oci_core_instance.lustre_mds.*.private_ip, count.index)}"
        user                = "${var.ssh_user}"
        private_key         = "${var.ssh_private_key}"
        bastion_host        = "${oci_core_instance.bastion.*.public_ip[0]}"
        bastion_port        = "22"
        bastion_user        = "${var.ssh_user}"
        bastion_private_key = "${var.ssh_private_key}"
      }
      inline = [
        "set -x",
        "echo about to run /tmp/nodes-cloud-init-complete-status-check.sh",
        "sudo -s bash -c 'set -x && chmod 777 /tmp/*.sh'",        
        "sudo -s bash -c 'set -x && /tmp/nodes-cloud-init-complete-status-check.sh'",
        "sudo -s bash -c \"set -x && /tmp/mds_setup.sh ${var.enable_mdt_raid0} \"",
      ]
    }
}


/*
Resource to check if the user_data/cloud-init script was successfully completed.
*/
resource "null_resource" "lustre-oss-setup-after-kernel-update" {
    depends_on = ["oci_core_instance.lustre_oss" , "oci_core_volume.lustre_oss_blockvolume" , "oci_core_volume_attachment.blockvolume_attach" , "null_resource.lustre-mds-setup-after-kernel-update"]
    count               = "${var.lustre_oss_count}"
    triggers {
      instance_ids = "${join(",", oci_core_instance.lustre_oss.*.id)}"
    }

    provisioner "file" {
      source = "${var.ssh_private_key_path}"
      destination = "/home/${var.ssh_user}/.ssh/id_rsa"
      connection {
        agent               = false
        timeout             = "30m"
        host                = "${element(oci_core_instance.lustre_oss.*.private_ip, count.index)}"
        user                = "${var.ssh_user}"
        private_key         = "${var.ssh_private_key}"
        bastion_host        = "${oci_core_instance.bastion.*.public_ip[0]}"
        bastion_port        = "22"
        bastion_user        = "${var.ssh_user}"
        bastion_private_key = "${var.ssh_private_key}"
      }
    }

    provisioner "file" {
      source = "../scripts/nodes-cloud-init-complete-status-check.sh"
      destination = "/tmp/nodes-cloud-init-complete-status-check.sh"
      connection {
        agent               = false
        timeout             = "30m"
        host                = "${element(oci_core_instance.lustre_oss.*.private_ip, count.index)}"
        user                = "${var.ssh_user}"
        private_key         = "${var.ssh_private_key}"
        bastion_host        = "${oci_core_instance.bastion.*.public_ip[0]}"
        bastion_port        = "22"
        bastion_user        = "${var.ssh_user}"
        bastion_private_key = "${var.ssh_private_key}"
      }
    }

    provisioner "file" {
      source = "../scripts/oss_setup.sh"
      destination = "/tmp/oss_setup.sh"
      connection {
        agent               = false
        timeout             = "30m"
        host                = "${element(oci_core_instance.lustre_oss.*.private_ip, count.index)}"
        user                = "${var.ssh_user}"
        private_key         = "${var.ssh_private_key}"
        bastion_host        = "${oci_core_instance.bastion.*.public_ip[0]}"
        bastion_port        = "22"
        bastion_user        = "${var.ssh_user}"
        bastion_private_key = "${var.ssh_private_key}"
      }
    }


    provisioner "remote-exec" {
      connection {
        agent               = false
        timeout             = "30m"
        host                = "${element(oci_core_instance.lustre_oss.*.private_ip, count.index)}"
        user                = "${var.ssh_user}"
        private_key         = "${var.ssh_private_key}"
        bastion_host        = "${oci_core_instance.bastion.*.public_ip[0]}"
        bastion_port        = "22"
        bastion_user        = "${var.ssh_user}"
        bastion_private_key = "${var.ssh_private_key}"
      }
      inline = [
        "set -x",
        "echo about to run /tmp/nodes-cloud-init-complete-status-check.sh",
        "sudo -s bash -c 'set -x && chmod 777 /tmp/*.sh'",
        "sudo -s bash -c 'set -x && /tmp/nodes-cloud-init-complete-status-check.sh'",
        "sudo -s bash -c \"set -x && /tmp/oss_setup.sh ${var.enable_ost_raid0} \"",
      ]
    }
}


/*
Resource to check if the user_data/cloud-init script was successfully completed.
*/
resource "null_resource" "lustre-client-setup-after-kernel-update" {
    depends_on = ["oci_core_instance.lustre_client", "null_resource.lustre-oss-setup-after-kernel-update", "null_resource.lustre-mds-setup-after-kernel-update"  ]
    count               = "${var.lustre_client_count}"
    triggers {
      instance_ids = "${join(",", oci_core_instance.lustre_client.*.id)}"
    }

    provisioner "file" {
      source = "${var.ssh_private_key_path}"
      destination = "/home/${var.ssh_user}/.ssh/id_rsa"
      connection {
        agent               = false
        timeout             = "30m"
        host                = "${element(oci_core_instance.lustre_client.*.private_ip, count.index)}"
        user                = "${var.ssh_user}"
        private_key         = "${var.ssh_private_key}"
        bastion_host        = "${oci_core_instance.bastion.*.public_ip[0]}"
        bastion_port        = "22"
        bastion_user        = "${var.ssh_user}"
        bastion_private_key = "${var.ssh_private_key}"
      }
    }

    provisioner "file" {
      source = "../scripts/nodes-cloud-init-complete-status-check.sh"
      destination = "/tmp/nodes-cloud-init-complete-status-check.sh"
      connection {
        agent               = false
        timeout             = "30m"
        host                = "${element(oci_core_instance.lustre_client.*.private_ip, count.index)}"
        user                = "${var.ssh_user}"
        private_key         = "${var.ssh_private_key}"
        bastion_host        = "${oci_core_instance.bastion.*.public_ip[0]}"
        bastion_port        = "22"
        bastion_user        = "${var.ssh_user}"
        bastion_private_key = "${var.ssh_private_key}"
      }
    }

    provisioner "file" {
      source = "../scripts/client_setup.sh"
      destination = "/tmp/client_setup.sh"
      connection {
        agent               = false
        timeout             = "30m"
        host                = "${element(oci_core_instance.lustre_client.*.private_ip, count.index)}"
        user                = "${var.ssh_user}"
        private_key         = "${var.ssh_private_key}"
        bastion_host        = "${oci_core_instance.bastion.*.public_ip[0]}"
        bastion_port        = "22"
        bastion_user        = "${var.ssh_user}"
        bastion_private_key = "${var.ssh_private_key}"
      }
    }


    provisioner "remote-exec" {
      connection {
        agent               = false
        timeout             = "30m"
        host                = "${element(oci_core_instance.lustre_client.*.private_ip, count.index)}"
        user                = "${var.ssh_user}"
        private_key         = "${var.ssh_private_key}"
        bastion_host        = "${oci_core_instance.bastion.*.public_ip[0]}"
        bastion_port        = "22"
        bastion_user        = "${var.ssh_user}"
        bastion_private_key = "${var.ssh_private_key}"
      }
      inline = [
        "set -x",
        "echo about to run /tmp/nodes-cloud-init-complete-status-check.sh",
        "sudo -s bash -c 'set -x && chmod 777 /tmp/*.sh'",
        "sudo -s bash -c 'set -x && /tmp/nodes-cloud-init-complete-status-check.sh'",
        "sudo -s bash -c 'set -x && /tmp/client_setup.sh'",
      ]
    }
}



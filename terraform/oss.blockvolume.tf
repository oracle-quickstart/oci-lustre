/*Copyright © 2018, Oracle and/or its affiliates. All rights reserved.

The Universal Permissive License (UPL), Version 1.0*/


resource "oci_core_volume" "lustre_oss_blockvolume" {
  #count               = "${var.lustre_oss_count * var.lustre_ost_count}"
  count               = "${var.lustre_oss_count * var.lustre_ost_count}"

  availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[var.AD - 1],"name")}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "lustre-oss${(count.index%var.lustre_oss_count+1)}-vol${(count.index%var.lustre_ost_count+1)}"
  size_in_gbs         = "${var.data_volume_size}"
}


resource "oci_core_volume_attachment" "blockvolume_attach" {
  attachment_type = "iscsi"
  count           = "${var.lustre_oss_count * var.lustre_ost_count}"
  compartment_id  = "${var.compartment_ocid}"
  instance_id     = "${element(oci_core_instance.lustre_oss.*.id, count.index%var.lustre_oss_count)}"
  volume_id       = "${element(oci_core_volume.lustre_oss_blockvolume.*.id, count.index)}"

  provisioner "remote-exec" {
    connection {
      agent               = false
      timeout             = "30m"
      host                = "${element(oci_core_instance.lustre_oss.*.private_ip, count.index%var.lustre_oss_count )}"
      user                = "${var.ssh_user}"
      private_key         = "${var.ssh_private_key}"
      bastion_host        = "${oci_core_instance.bastion.*.public_ip[0]}"
      bastion_port        = "22"
      bastion_user        = "${var.ssh_user}"
      bastion_private_key = "${var.ssh_private_key}"
    }

    inline = [
      "sudo -s bash -c 'set -x && iscsiadm -m node -o new -T ${self.iqn} -p ${self.ipv4}:${self.port}'",
      "sudo -s bash -c 'set -x && iscsiadm -m node -o update -T ${self.iqn} -n node.startup -v automatic '",
      "sudo -s bash -c 'set -x && iscsiadm -m node -T ${self.iqn} -p ${self.ipv4}:${self.port} -l '",
      #"sudo -s bash -c 'set -x && pvcreate -y  /dev/sdb'",
      #"sudo -s bash -c 'mkfs.xfs -f /dev/sdb'",
    ]
  }
}




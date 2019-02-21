



output "SSH login " {
value = <<END
        Bastion: ssh -i ~/.ssh/id_rsa ${var.ssh_user}@${oci_core_instance.bastion.*.public_ip[0]}
        MDS: ssh -i ~/.ssh/id_rsa ${var.ssh_user}@${oci_core_instance.lustre_mds.*.public_ip[0]}
        OSS: ssh -i ~/.ssh/id_rsa ${var.ssh_user}@${oci_core_instance.lustre_oss.*.public_ip[0]}
        Client: ssh -i ~/.ssh/id_rsa ${var.ssh_user}@${oci_core_instance.lustre_client.*.public_ip[0]}


END
}






output "SSH_login_to_first_server" {
  value = <<END

        Bastion: ssh -i ~/.ssh/id_rsa ${var.ssh_user}@${oci_core_instance.bastion[0].public_ip}
        MDS: ssh -i ~/.ssh/id_rsa ${var.ssh_user}@${oci_core_instance.lustre_mds[0].public_ip}
        OSS: ssh -i ~/.ssh/id_rsa ${var.ssh_user}@${oci_core_instance.lustre_oss[0].public_ip}
        Client: ssh -i ~/.ssh/id_rsa ${var.ssh_user}@${oci_core_instance.lustre_client[0].public_ip}

END

}

output "Full_list_of_Servers" {
  value = <<END

        Bastion: ${join(",", oci_core_instance.bastion.*.public_ip)}   
        MDS: ${join(",", oci_core_instance.lustre_mds.*.public_ip)}
        OSS: ${join(",", oci_core_instance.lustre_oss.*.public_ip)}
        Client: ${join(",", oci_core_instance.lustre_client.*.public_ip)}

END

}


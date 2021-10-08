## Copyright © 2021, Oracle and/or its affiliates. 
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

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


output "Filesystem-Mgmt-Details" {
  value = <<END

Lustre Management Service Hostname: ${local.management_server_filesystem_vnic_hostname_prefix}1.${local.filesystem_subnet_domain_name}

END
}


output "SSH-login" {
  value = <<END

        Bastion: ssh -i CHANGEME ${var.ssh_user}@${element(concat(oci_core_instance.bastion.*.public_ip, [""]), 0)}

        Management Server: ssh -i CHANGEME  -o BatchMode=yes -o StrictHostkeyChecking=no  -o ProxyCommand="ssh -i CHANGEME -o BatchMode=yes -o StrictHostkeyChecking=no ${var.ssh_user}@${element(concat(oci_core_instance.bastion.*.public_ip, [""]), 0)} -W %h:%p %r" ${var.ssh_user}@${element(concat(oci_core_instance.management_server.*.private_ip, [""]), 0)}

        Metadata Server-1: ssh -i CHANGEME  -o BatchMode=yes -o StrictHostkeyChecking=no  -o ProxyCommand="ssh -i CHANGEME -o BatchMode=yes -o StrictHostkeyChecking=no ${var.ssh_user}@${element(concat(oci_core_instance.bastion.*.public_ip, [""]), 0)} -W %h:%p %r" ${var.ssh_user}@${element(concat(oci_core_instance.metadata_server.*.private_ip, [""]), 0)}

        Storage Server-1: ssh -i CHANGEME  -o BatchMode=yes -o StrictHostkeyChecking=no  -o ProxyCommand="ssh -i CHANGEME -o BatchMode=yes -o StrictHostkeyChecking=no ${var.ssh_user}@${element(concat(oci_core_instance.bastion.*.public_ip, [""]), 0)} -W %h:%p %r" ${var.ssh_user}@${element(concat(oci_core_instance.storage_server.*.private_ip, [""]), 0)}

        Client-1: ssh -i CHANGEME  -o BatchMode=yes -o StrictHostkeyChecking=no  -o ProxyCommand="ssh -i CHANGEME -o BatchMode=yes -o StrictHostkeyChecking=no ${var.ssh_user}@${element(concat(oci_core_instance.bastion.*.public_ip, [""]), 0)} -W %h:%p %r" ${var.ssh_user}@${element(concat(oci_core_instance.client_node.*.private_ip, [""]), 0)}

END
}

output "generated_ssh_private_key" {
  value     = tls_private_key.ssh.private_key_pem
  sensitive = true
}


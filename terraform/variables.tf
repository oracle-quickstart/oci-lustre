###
## Variables.tf for Terraform
###

variable "tenancy_ocid" {
}

variable "user_ocid" {
}

variable "fingerprint" {
}

variable "private_key_path" {
}

variable "region" {
  default = "us-phoenix-1"
}

variable "compartment_ocid" {
}

variable "ssh_public_key" {
}

variable "ssh_private_key" {
}

variable "ssh_private_key_path" {
}

# For instances created using Oracle Linux and CentOS images, the user name opc is created automatically.
# For instances created using the Ubuntu image, the user name ubuntu is created automatically.
# The ubuntu user has sudo privileges and is configured for remote access over the SSH v2 protocol using RSA keys. The SSH public keys that you specify while creating instances are added to the /home/ubuntu/.ssh/authorized_keys file.
# For more details: https://docs.cloud.oracle.com/iaas/Content/Compute/References/images.htm#one
variable "ssh_user" {
  default = "opc"
}

# For Ubuntu images,  set to ubuntu. 
# variable "ssh_user" { default = "ubuntu" }

# 2OSS_cluster in PHX AD-2 - INTZAC*
# 4OSS_cluster in PHX AD-3 - INTZAC*
variable "AD" {
  default = "2"
}

variable "VPC-CIDR" {
  default = "10.0.0.0/16"
}

variable "InstanceImageOCID" {
  type = map(string)
  default = {
    // https://docs.cloud.oracle.com/iaas/images/image/96ad11d8-2a4f-4154-b128-4d4510756983/
    // See https://docs.us-phoenix-1.oraclecloud.com/images/ or https://docs.cloud.oracle.com/iaas/images/
    // Oracle-provided image "CentOS-7-2018.08.15-0"
    eu-frankfurt-1 = "ocid1.image.oc1.eu-frankfurt-1.aaaaaaaavsw2452x5psvj7lzp7opjcpj3yx7or4swwzl5vrdydxtfv33sbmqa"
    us-ashburn-1   = "ocid1.image.oc1.iad.aaaaaaaahhgvnnprjhfmzynecw2lqkwhztgibz5tcs3x4d5rxmbqcmesyqta"
    uk-london-1    = "ocid1.image.oc1.uk-london-1.aaaaaaaa3iltzfhdk5m6f27wcuw4ttcfln54twkj66rsbn52yemg3gi5pkqa"
    us-phoenix-1   = "ocid1.image.oc1.phx.aaaaaaaaa2ph5vy4u7vktmf3c6zemhlncxkomvay2afrbw5vouptfbydwmtq"
  }
}

# Compute Instance counts
# Bastion server count.  1 should be enough
variable "bastion_server_count" {
  default = "1"
}

# bastion instance shape
variable "bastion_server_shape" {
  default = "VM.Standard2.2"
}

# MDS server count
variable "lustre_mds_count" {
  default = "1"
}

# MDS server shape
variable "lustre_mds_server_shape" {
  default = "BM.DenseIO2.52"
}

# size in GiB for each MDT disk.
variable "mdt_block_volume_size" {
  default = "800"
}

#eg: 2 block storage volume per MDS node.
variable "lustre_mdt_count" {
  default = "1"
}

variable "enable_mdt_raid0" {
  default = "false"
}

variable "mgs" {
  type = map(string)
  default = {
    hostname_prefix_nic0 = "lustre-mds-server-nic0-"
    hostname_prefix_nic1 = "lustre-mds-server-nic1-"
    hostname_nic0        = "lustre-mds-server-nic0-1"
    hostname_nic1        = "lustre-mds-server-nic1-1"
  }
}

variable "mds" {
  type = map(string)
  default = {
    hostname_prefix_nic0 = "lustre-mds-server-nic0-"
    hostname_prefix_nic1 = "lustre-mds-server-nic1-"
  }
}

# OSS server count.
variable "lustre_oss_count" {
  default = "2"
}

# OSS server shape
variable "lustre_oss_server_shape" {
  default = "BM.DenseIO2.52"
}

# size in GiB for each OST disk.
variable "ost_block_volume_size" {
  default = "800"
}

#eg: 4 block storage volume per OSS node.
variable "lustre_ost_count" {
  default = "16"
}

variable "enable_ost_raid0" {
  default = "true"
}

variable "oss" {
  type = map(string)
  default = {
    hostname_prefix_nic0 = "lustre-oss-server-nic0-"
    hostname_prefix_nic1 = "lustre-oss-server-nic1-"
  }
}

# Lustre Client server count   
variable "lustre_client_count" {
  default = "5"
}

# Lustre Client server shape
variable "lustre_client_shape" {
  default = "VM.Standard2.24"
}




## Copyright © 2021, Oracle and/or its affiliates. 
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

variable "tenancy_ocid" {}
variable "user_ocid" {}
variable "fingerprint" {}
variable "private_key_path" {}
variable "region" {}
variable "compartment_ocid" {}

provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.region
}

resource "oci_core_virtual_network" "my_vcn" {
  cidr_block     = "192.168.0.0/16"
  compartment_id = var.compartment_ocid
  display_name   = "myVCN"
  dns_label      = "myVCN"
}

resource "oci_core_internet_gateway" "my_igw" {
  compartment_id = var.compartment_ocid
  display_name   = "myIGW"
  vcn_id         = oci_core_virtual_network.my_vcn.id
}

resource "oci_core_route_table" "my_pub_rt" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.my_vcn.id
  display_name   = "myPubRT"
  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.my_igw.id
  }
}

resource "oci_core_nat_gateway" "my_natgw" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.my_vcn.id
  display_name   = "myNATGW"
}

resource "oci_core_route_table" "my_priv_rt" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.my_vcn.id
  display_name   = "myPrivRT"
  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.my_natgw.id
  }
}

resource "oci_core_security_list" "my_pub_sec_list" {
  compartment_id = var.compartment_ocid
  display_name   = "myPubSecList"
  vcn_id         = oci_core_virtual_network.my_vcn.id

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "6"
  }

  ingress_security_rules {
    tcp_options {
      max = 22
      min = 22
    }
    protocol = "6"
    source   = "0.0.0.0/0"
  }
}

resource "oci_core_security_list" "my_priv_sec_list" {
  compartment_id = var.compartment_ocid
  display_name   = "myPrivSecList"
  vcn_id         = oci_core_virtual_network.my_vcn.id

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }

  ingress_security_rules {
    protocol = "all"
    source   = "192.168.0.0/16"
  }
}

resource "oci_core_subnet" "my_pub_subnet" {
  cidr_block        = "192.168.1.0/24"
  display_name      = "my_pub_subnet"
  compartment_id    = var.compartment_ocid
  vcn_id            = oci_core_virtual_network.my_vcn.id
  route_table_id    = oci_core_route_table.my_pub_rt.id
  security_list_ids = [oci_core_virtual_network.my_vcn.default_security_list_id, oci_core_security_list.my_pub_sec_list.id]
  dhcp_options_id   = oci_core_virtual_network.my_vcn.default_dhcp_options_id
  dns_label         = "public"
}

resource "oci_core_subnet" "my_priv_storage_subnet" {
  cidr_block                 = "192.168.2.0/24"
  display_name               = "my_priv_storage_subnet"
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_virtual_network.my_vcn.id
  route_table_id             = oci_core_route_table.my_priv_rt.id
  security_list_ids          = [oci_core_virtual_network.my_vcn.default_security_list_id, oci_core_security_list.my_priv_sec_list.id]
  dhcp_options_id            = oci_core_virtual_network.my_vcn.default_dhcp_options_id
  prohibit_public_ip_on_vnic = true
  dns_label                  = "storage"
}

resource "oci_core_subnet" "my_priv_fs_subnet" {
  cidr_block                 = "192.168.3.0/24"
  display_name               = "my_priv_fs_subnet"
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_virtual_network.my_vcn.id
  route_table_id             = oci_core_route_table.my_priv_rt.id
  security_list_ids          = [oci_core_virtual_network.my_vcn.default_security_list_id, oci_core_security_list.my_priv_sec_list.id]
  dhcp_options_id            = oci_core_virtual_network.my_vcn.default_dhcp_options_id
  prohibit_public_ip_on_vnic = true
  dns_label                  = "fs"
}

module "oci-lustre" {
  source            = "github.com/oracle-quickstart/oci-lustre"
  tenancy_ocid      = var.tenancy_ocid
  user_ocid         = var.user_ocid
  fingerprint       = var.fingerprint
  region            = var.region
  private_key_path  = var.private_key_path
  compartment_ocid  = var.compartment_ocid
  ad_number         = 0
  use_existing_vcn  = true
  vcn_id            = oci_core_virtual_network.my_vcn.id
  bastion_subnet_id = oci_core_subnet.my_pub_subnet.id
  storage_subnet_id = oci_core_subnet.my_priv_storage_subnet.id
  fs_subnet_id      = oci_core_subnet.my_priv_fs_subnet.id
}

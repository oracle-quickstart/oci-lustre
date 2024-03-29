## Copyright © 2021, Oracle and/or its affiliates. 
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

resource "oci_core_virtual_network" "hfs" {
  count          = var.use_existing_vcn ? 0 : 1
  cidr_block     = var.vpc_cidr
  compartment_id = var.compartment_ocid
  display_name   = "hfs"
  dns_label      = "hfs"
  defined_tags   = { "${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }
}

resource "oci_core_internet_gateway" "internet_gateway" {
  count          = var.use_existing_vcn ? 0 : 1
  compartment_id = var.compartment_ocid
  display_name   = "internet_gateway"
  vcn_id         = oci_core_virtual_network.hfs[0].id
}

resource "oci_core_route_table" "pubic_route_table" {
  count          = var.use_existing_vcn ? 0 : 1
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.hfs[0].id
  display_name   = "RouteTableForComplete"
  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.internet_gateway[0].id
  }
  defined_tags = { "${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }
}


resource "oci_core_nat_gateway" "nat_gateway" {
  count          = var.use_existing_vcn ? 0 : 1
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.hfs[0].id
  display_name   = "nat_gateway"
  defined_tags   = { "${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }
}


resource "oci_core_route_table" "private_route_table" {
  count          = var.use_existing_vcn ? 0 : 1
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.hfs[0].id
  display_name   = "private_route_tableForComplete"
  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.nat_gateway[0].id
  }
  defined_tags = { "${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }
}

resource "oci_core_security_list" "public_security_list" {
  count          = var.use_existing_vcn ? 0 : 1
  compartment_id = var.compartment_ocid
  display_name   = "Public Security List"
  vcn_id         = oci_core_virtual_network.hfs[0].id

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
  defined_tags = { "${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }
}


resource "oci_core_security_list" "private_security_list" {
  count          = var.use_existing_vcn ? 0 : 1
  compartment_id = var.compartment_ocid
  display_name   = "Private Security List"
  vcn_id         = oci_core_virtual_network.hfs[0].id

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }

  ingress_security_rules {
    protocol = "all"
    source   = var.vpc_cidr
  }
  defined_tags = { "${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }
}


# Regional subnet - public
resource "oci_core_subnet" "public" {
  count             = var.use_existing_vcn ? 0 : 1
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index)
  display_name      = "public"
  compartment_id    = var.compartment_ocid
  vcn_id            = oci_core_virtual_network.hfs[0].id
  route_table_id    = oci_core_route_table.pubic_route_table[0].id
  security_list_ids = [oci_core_virtual_network.hfs[0].default_security_list_id, oci_core_security_list.public_security_list[0].id]
  dhcp_options_id   = oci_core_virtual_network.hfs[0].default_dhcp_options_id
  dns_label         = "public"
  defined_tags      = { "${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }
}


# Regional subnet - private
resource "oci_core_subnet" "storage" {
  count                      = var.use_existing_vcn ? 0 : 1
  cidr_block                 = cidrsubnet(var.vpc_cidr, 8, count.index + 3)
  display_name               = "private_storage"
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_virtual_network.hfs[0].id
  route_table_id             = oci_core_route_table.private_route_table[0].id
  security_list_ids          = [oci_core_virtual_network.hfs[0].default_security_list_id, oci_core_security_list.private_security_list[0].id]
  dhcp_options_id            = oci_core_virtual_network.hfs[0].default_dhcp_options_id
  prohibit_public_ip_on_vnic = true
  dns_label                  = "storage"
  defined_tags               = { "${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }
}


resource "oci_core_subnet" "fs" {
  count                      = var.use_existing_vcn ? 0 : 1
  cidr_block                 = cidrsubnet(var.vpc_cidr, 8, count.index + 6)
  display_name               = "private_fs"
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_virtual_network.hfs[0].id
  route_table_id             = oci_core_route_table.private_route_table[0].id
  security_list_ids          = [oci_core_virtual_network.hfs[0].default_security_list_id, oci_core_security_list.private_security_list[0].id]
  dhcp_options_id            = oci_core_virtual_network.hfs[0].default_dhcp_options_id
  prohibit_public_ip_on_vnic = true
  dns_label                  = "fs"
  defined_tags               = { "${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }
}

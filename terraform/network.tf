/*
All network resources for this template
*/

<<<<<<< HEAD
resource "oci_core_virtual_network" "lustre" {
  cidr_block     = var.VPC-CIDR
  compartment_id = var.compartment_ocid
  display_name   = "lustre"
  dns_label      = "lustre"
=======
resource "oci_core_virtual_network" "sas_vcn" {
  cidr_block     = var.VPC-CIDR
  compartment_id = var.compartment_ocid
  display_name   = "sasvcn"
  dns_label      = "sasvcn"
>>>>>>> 7dcc85c22cc793cc0d8f0481f827a955f5537c61
}

resource "oci_core_internet_gateway" "sas_internet_gateway" {
  compartment_id = var.compartment_ocid
  display_name   = "sas_internet_gateway"
<<<<<<< HEAD
  vcn_id         = oci_core_virtual_network.lustre.id
=======
  vcn_id         = oci_core_virtual_network.sas_vcn.id
>>>>>>> 7dcc85c22cc793cc0d8f0481f827a955f5537c61
}

resource "oci_core_route_table" "RouteForComplete" {
  compartment_id = var.compartment_ocid
<<<<<<< HEAD
  vcn_id         = oci_core_virtual_network.lustre.id
=======
  vcn_id         = oci_core_virtual_network.sas_vcn.id
>>>>>>> 7dcc85c22cc793cc0d8f0481f827a955f5537c61
  display_name   = "RouteTableForComplete"
  route_rules {
    cidr_block        = "0.0.0.0/0"
    network_entity_id = oci_core_internet_gateway.sas_internet_gateway.id
  }
}

resource "oci_core_nat_gateway" "sas_nat_gateway" {
  compartment_id = var.compartment_ocid
<<<<<<< HEAD
  vcn_id         = oci_core_virtual_network.lustre.id
=======
  vcn_id         = oci_core_virtual_network.sas_vcn.id
>>>>>>> 7dcc85c22cc793cc0d8f0481f827a955f5537c61
  display_name   = "sas_nat_gateway"
}

resource "oci_core_route_table" "PrivateRouteTable" {
  compartment_id = var.compartment_ocid
<<<<<<< HEAD
  vcn_id         = oci_core_virtual_network.lustre.id
=======
  vcn_id         = oci_core_virtual_network.sas_vcn.id
>>>>>>> 7dcc85c22cc793cc0d8f0481f827a955f5537c61
  display_name   = "PrivateRouteTableForComplete"

  route_rules {
    destination       = "0.0.0.0/0"
    network_entity_id = oci_core_nat_gateway.sas_nat_gateway.id
  }
}

resource "oci_core_security_list" "PublicSubnet" {
  compartment_id = var.compartment_ocid
  display_name   = "Public Subnet"
<<<<<<< HEAD
  vcn_id         = oci_core_virtual_network.lustre.id
=======
  vcn_id         = oci_core_virtual_network.sas_vcn.id
>>>>>>> 7dcc85c22cc793cc0d8f0481f827a955f5537c61
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
  ingress_security_rules {
    protocol = "all"
    source   = var.VPC-CIDR
  }
<<<<<<< HEAD
=======
  ingress_security_rules {
    tcp_options {
      max = 80
      min = 80
    }
    protocol = "6"
    source   = "0.0.0.0/0"
  }
  ingress_security_rules {
    tcp_options {
      max = 443
      min = 443
    }
    protocol = "6"
    source   = "0.0.0.0/0"
  }
>>>>>>> 7dcc85c22cc793cc0d8f0481f827a955f5537c61
}

resource "oci_core_security_list" "PrivateSubnet" {
  compartment_id = var.compartment_ocid
  display_name   = "Private"
<<<<<<< HEAD
  vcn_id         = oci_core_virtual_network.lustre.id
=======
  vcn_id         = oci_core_virtual_network.sas_vcn.id
>>>>>>> 7dcc85c22cc793cc0d8f0481f827a955f5537c61

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }

  egress_security_rules {
    protocol    = "all"
    destination = var.VPC-CIDR
  }

  ingress_security_rules {
    protocol = "6"
    source   = var.VPC-CIDR
  }

  ingress_security_rules {
    tcp_options {
      max = 22
      min = 22
    }
    protocol = "6"
    source   = var.VPC-CIDR
  }
<<<<<<< HEAD
=======
  ingress_security_rules {
    tcp_options {
      max = 8850
      min = 8850
    }
    protocol = "6"
    source   = var.VPC-CIDR
  }
  ingress_security_rules {
    tcp_options {
      max = 80
      min = 80
    }
    protocol = "6"
    source   = var.VPC-CIDR
  }
  ingress_security_rules {
    tcp_options {
      max = 443
      min = 443
    }
    protocol = "6"
    source   = var.VPC-CIDR
  }
>>>>>>> 7dcc85c22cc793cc0d8f0481f827a955f5537c61

  # Used by PostgreSQL database.
  ingress_security_rules {
    tcp_options {
      max = 8060
      min = 8060
    }
    protocol = "6"
    source   = var.VPC-CIDR
  }
  ingress_security_rules {
    tcp_options {
      max = 8061
      min = 8061
    }
    protocol = "6"
    source   = var.VPC-CIDR
  }
  ingress_security_rules {
    tcp_options {
      max = 9000
      min = 8000
    }
    protocol = "6"
    source   = var.VPC-CIDR
  }
  ingress_security_rules {
    tcp_options {
      max = 27009
      min = 27000
    }
    protocol = "6"
    source   = var.VPC-CIDR
  }
}

## Publicly Accessable Subnet Setup

resource "oci_core_subnet" "public" {
  count = "1"

  #availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[var.AD - 1],"name")}"
  cidr_block        = cidrsubnet(var.VPC-CIDR, 8, count.index)
  display_name      = "public_${count.index}"
  compartment_id    = var.compartment_ocid
<<<<<<< HEAD
  vcn_id            = oci_core_virtual_network.lustre.id
  route_table_id    = oci_core_route_table.RouteForComplete.id
  security_list_ids = [oci_core_security_list.PublicSubnet.id]
  dhcp_options_id   = oci_core_virtual_network.lustre.default_dhcp_options_id
=======
  vcn_id            = oci_core_virtual_network.sas_vcn.id
  route_table_id    = oci_core_route_table.RouteForComplete.id
  security_list_ids = [oci_core_security_list.PublicSubnet.id]
  dhcp_options_id   = oci_core_virtual_network.sas_vcn.default_dhcp_options_id
>>>>>>> 7dcc85c22cc793cc0d8f0481f827a955f5537c61
  dns_label         = "public${count.index}"
}

resource "oci_core_subnet" "publicb" {
  count = "1"

  #availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[var.AD - 1],"name")}"
  cidr_block        = cidrsubnet(var.VPC-CIDR, 8, count.index + 3)
  display_name      = "publicb_${count.index}"
  compartment_id    = var.compartment_ocid
<<<<<<< HEAD
  vcn_id            = oci_core_virtual_network.lustre.id
  route_table_id    = oci_core_route_table.RouteForComplete.id
  security_list_ids = [oci_core_security_list.PublicSubnet.id]
  dhcp_options_id   = oci_core_virtual_network.lustre.default_dhcp_options_id
=======
  vcn_id            = oci_core_virtual_network.sas_vcn.id
  route_table_id    = oci_core_route_table.RouteForComplete.id
  security_list_ids = [oci_core_security_list.PublicSubnet.id]
  dhcp_options_id   = oci_core_virtual_network.sas_vcn.default_dhcp_options_id
>>>>>>> 7dcc85c22cc793cc0d8f0481f827a955f5537c61
  dns_label         = "publicb${count.index}"
}

## Private Subnet Setup 

resource "oci_core_subnet" "private" {
  count = "1"

  #availability_domain        = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[var.AD - 1],"name")}"
  cidr_block                 = cidrsubnet(var.VPC-CIDR, 8, count.index + 6)
  display_name               = "private_${count.index}"
  compartment_id             = var.compartment_ocid
<<<<<<< HEAD
  vcn_id                     = oci_core_virtual_network.lustre.id
  route_table_id             = oci_core_route_table.PrivateRouteTable.id
  security_list_ids          = [oci_core_security_list.PrivateSubnet.id]
  dhcp_options_id            = oci_core_virtual_network.lustre.default_dhcp_options_id
=======
  vcn_id                     = oci_core_virtual_network.sas_vcn.id
  route_table_id             = oci_core_route_table.PrivateRouteTable.id
  security_list_ids          = [oci_core_security_list.PrivateSubnet.id]
  dhcp_options_id            = oci_core_virtual_network.sas_vcn.default_dhcp_options_id
>>>>>>> 7dcc85c22cc793cc0d8f0481f827a955f5537c61
  prohibit_public_ip_on_vnic = "true"
  dns_label                  = "private${count.index}"
}

resource "oci_core_subnet" "privateb" {
  count = "1"

  #availability_domain        = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[var.AD - 1],"name")}"
  cidr_block                 = cidrsubnet(var.VPC-CIDR, 8, count.index + 9)
  display_name               = "privateb_${count.index}"
  compartment_id             = var.compartment_ocid
<<<<<<< HEAD
  vcn_id                     = oci_core_virtual_network.lustre.id
  route_table_id             = oci_core_route_table.PrivateRouteTable.id
  security_list_ids          = [oci_core_security_list.PrivateSubnet.id]
  dhcp_options_id            = oci_core_virtual_network.lustre.default_dhcp_options_id
=======
  vcn_id                     = oci_core_virtual_network.sas_vcn.id
  route_table_id             = oci_core_route_table.PrivateRouteTable.id
  security_list_ids          = [oci_core_security_list.PrivateSubnet.id]
  dhcp_options_id            = oci_core_virtual_network.sas_vcn.default_dhcp_options_id
>>>>>>> 7dcc85c22cc793cc0d8f0481f827a955f5537c61
  prohibit_public_ip_on_vnic = "true"
  dns_label                  = "privateb${count.index}"
}


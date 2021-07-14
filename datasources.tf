# Gets a list of Availability Domains
data "oci_identity_availability_domains" "availability_domains" {
  compartment_id = var.compartment_ocid
}


data "oci_identity_region_subscriptions" "home_region_subscriptions" {
  tenancy_id = var.tenancy_ocid

  filter {
    name   = "is_home_region"
    values = [true]
  }
}

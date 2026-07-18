resource "oci_identity_group" "this" {
  compartment_id = var.tenancy_id
  name           = var.group_name
  description    = var.group_description

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}

resource "oci_identity_policy" "this" {
  compartment_id = var.compartment_id
  name           = var.policy_name
  description    = var.policy_description
  statements     = var.statements

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}

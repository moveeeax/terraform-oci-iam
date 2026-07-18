provider "oci" {}

module "iam" {
  source = "../.."

  compartment_id = var.compartment_id
  tenancy_id     = var.tenancy_id
  group_name     = "example-readers"
  policy_name    = "example-readers-policy"

  statements = [
    "Allow group example-readers to read all-resources in compartment id ${var.compartment_id}"
  ]

  freeform_tags = {
    Environment = "sandbox"
    ManagedBy   = "terraform"
  }
}

variable "compartment_id" {
  description = "Compartment OCID the example policy applies to."
  type        = string
}

variable "tenancy_id" {
  description = "Tenancy OCID in which to create the example group."
  type        = string
}

output "group_id" {
  value = module.iam.group_id
}

output "policy_id" {
  value = module.iam.policy_id
}

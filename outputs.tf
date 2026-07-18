output "group_id" {
  description = "OCID of the IAM group."
  value       = oci_identity_group.this.id
}

output "group_name" {
  description = "Name of the IAM group."
  value       = oci_identity_group.this.name
}

output "policy_id" {
  description = "OCID of the IAM policy."
  value       = oci_identity_policy.this.id
}

output "statements" {
  description = "Policy statements applied."
  value       = oci_identity_policy.this.statements
}

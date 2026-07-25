locals {
  # A wildcard subject (any-user / any-group) or a wildcard tenancy scope
  # (any-tenancy, used by Endorse/Admit for cross-tenancy access) with no `where`
  # clause grants the permission to every principal that can reach the policy.
  # This is the OCI analogue of an AWS trust policy with Principal "*" and no
  # condition, and is almost never what the author meant.
  wildcard_subject_statements = [
    for s in var.statements : s
    if can(regex("(?i)\\b(any-user|any-group|any-tenancy)\\b", s)) && !can(regex("(?i)\\bwhere\\b", s))
  ]

  # `manage all-resources in tenancy` is full tenancy administrator. Compartment
  # scoped `manage all-resources` is a normal delegation pattern and is not flagged.
  tenancy_admin_statements = [
    for s in var.statements : s
    if can(regex("(?i)\\bmanage\\s+all-resources\\s+in\\s+tenancy\\b", s))
  ]
}

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

  lifecycle {
    precondition {
      condition     = var.allow_privileged_statements || length(local.wildcard_subject_statements) == 0
      error_message = "Policy statement uses a wildcard subject/scope (any-user, any-group or any-tenancy) with no `where` condition, which grants the permission to every principal that can reach this policy. Add a `where` condition narrowing the grant, or set allow_privileged_statements = true if this is intentional. Offending statements: ${join(" | ", local.wildcard_subject_statements)}"
    }

    precondition {
      condition     = var.allow_privileged_statements || length(local.tenancy_admin_statements) == 0
      error_message = "Policy statement grants `manage all-resources in tenancy`, i.e. full tenancy administrator. Scope it to a compartment, or set allow_privileged_statements = true if this is intentional. Offending statements: ${join(" | ", local.tenancy_admin_statements)}"
    }
  }
}

# Warning, not an error: the module's contract is "a group plus the policy that
# grants it permissions". If no statement names the group being created, the policy
# is almost certainly a typo away from granting nothing at all — OCI accepts a
# statement referring to a non-existent group without complaint.
check "policy_references_managed_group" {
  assert {
    condition = anytrue([
      for s in var.statements : strcontains(lower(s), lower("group ${var.group_name}"))
    ])
    error_message = "None of the policy statements reference \"group ${var.group_name}\". The group will be created with no permissions attached; check for a typo in the statement subject."
  }
}

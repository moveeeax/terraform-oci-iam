# Test-only requirement: `mock_provider` needs Terraform >= 1.7 (OpenTofu >= 1.7).
# The module itself still supports >= 1.5, so required_version in versions.tf is
# deliberately left alone — consumers on 1.5/1.6 are unaffected.
mock_provider "oci" {}

variables {
  compartment_id = "ocid1.compartment.oc1..aaaaaaaaexamplecompartment"
  tenancy_id     = "ocid1.tenancy.oc1..aaaaaaaaexampletenancy"
  group_name     = "example-readers"
  policy_name    = "example-readers-policy"
  statements = [
    "Allow group example-readers to read all-resources in compartment id ocid1.compartment.oc1..aaaaaaaaexamplecompartment",
  ]
}

run "defaults_are_safe" {
  command = apply

  assert {
    condition     = oci_identity_group.this.compartment_id == var.tenancy_id
    error_message = "Groups must be created at the tenancy root, not in the policy's compartment."
  }

  assert {
    condition     = var.allow_privileged_statements == false
    error_message = "Privileged statements must be opt-in, not the default."
  }

  assert {
    condition     = oci_identity_policy.this.compartment_id == var.compartment_id
    error_message = "The policy must be attached to the requested compartment."
  }
}

# --- statement syntax ------------------------------------------------------

run "rejects_empty_statement_list" {
  command = plan
  variables { statements = [] }

  expect_failures = [var.statements]
}

run "rejects_typo_in_policy_verb" {
  command = plan
  variables {
    statements = ["Alow group example-readers to read all-resources in tenancy"]
  }

  expect_failures = [var.statements]
}

run "rejects_statement_missing_permission_verb" {
  command = plan
  variables {
    statements = ["Allow group example-readers to all-resources in tenancy"]
  }

  expect_failures = [var.statements]
}

run "rejects_statement_missing_scope" {
  command = plan
  variables {
    statements = ["Allow group example-readers to manage buckets"]
  }

  expect_failures = [var.statements]
}

run "accepts_endorse_and_admit_statements" {
  command = plan
  variables {
    statements = [
      "Endorse group example-readers to manage buckets in any-tenancy where request.region = 'uk-london-1'",
      "Admit group example-readers of tenancy partner to read buckets in compartment id ocid1.compartment.oc1..aaaaaaaaexamplecompartment",
    ]
  }
}

# --- over-broad grants -----------------------------------------------------

run "rejects_any_user_without_condition" {
  command = plan
  variables {
    statements = [
      "Allow any-user to use api-keys in tenancy",
      "Allow group example-readers to read all-resources in compartment id ocid1.compartment.oc1..aaaaaaaaexamplecompartment",
    ]
  }

  expect_failures = [oci_identity_policy.this]
}

run "rejects_admit_from_any_tenancy_without_condition" {
  command = plan
  variables {
    statements = [
      "Admit any-user of any-tenancy to read buckets in compartment id ocid1.compartment.oc1..aaaaaaaaexamplecompartment",
      "Allow group example-readers to read all-resources in compartment id ocid1.compartment.oc1..aaaaaaaaexamplecompartment",
    ]
  }

  expect_failures = [oci_identity_policy.this]
}

run "accepts_any_user_with_where_condition" {
  command = plan
  variables {
    statements = [
      "Allow any-user to use api-keys in tenancy where target.user.id = request.user.id",
      "Allow group example-readers to read all-resources in compartment id ocid1.compartment.oc1..aaaaaaaaexamplecompartment",
    ]
  }
}

run "rejects_tenancy_wide_manage_all_resources" {
  command = plan
  variables {
    statements = ["Allow group example-readers to manage all-resources in tenancy"]
  }

  expect_failures = [oci_identity_policy.this]
}

run "accepts_compartment_scoped_manage_all_resources" {
  command = plan
  variables {
    statements = ["Allow group example-readers to manage all-resources in compartment id ocid1.compartment.oc1..aaaaaaaaexamplecompartment"]
  }
}

run "privileged_opt_in_permits_tenancy_administrator" {
  command = plan
  variables {
    allow_privileged_statements = true
    statements                  = ["Allow group example-readers to manage all-resources in tenancy"]
  }
}

# --- group/policy pairing --------------------------------------------------

run "warns_when_no_statement_references_the_managed_group" {
  command = plan
  variables {
    statements = ["Allow group exampel-readers to read all-resources in compartment id ocid1.compartment.oc1..aaaaaaaaexamplecompartment"]
  }

  expect_failures = [check.policy_references_managed_group]
}

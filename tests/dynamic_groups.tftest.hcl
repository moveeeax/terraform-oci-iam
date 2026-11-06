# Test-only requirement: `mock_provider` needs Terraform >= 1.7 (OpenTofu >= 1.7).
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

run "no_dynamic_groups_by_default" {
  command = plan

  assert {
    condition     = length(oci_identity_dynamic_group.this) == 0
    error_message = "No dynamic groups should be created unless requested."
  }
}

run "creates_dynamic_groups_at_tenancy_level" {
  command = apply

  variables {
    dynamic_groups = {
      app-instances = {
        matching_rule = "ALL {instance.compartment.id = 'ocid1.compartment.oc1..aaaaaaaaexamplecompartment'}"
        description   = "Instances of the app compartment"
      }
      "fn.workers" = {
        matching_rule = "ALL {resource.type = 'fnfunc', resource.compartment.id = 'ocid1.compartment.oc1..aaaaaaaaexamplecompartment'}"
      }
    }
    statements = [
      "Allow group example-readers to read all-resources in compartment id ocid1.compartment.oc1..aaaaaaaaexamplecompartment",
      "Allow dynamic-group app-instances, fn.workers to read secret-family in compartment id ocid1.compartment.oc1..aaaaaaaaexamplecompartment",
    ]
  }

  assert {
    condition     = length(oci_identity_dynamic_group.this) == 2
    error_message = "Every dynamic_groups entry should create one dynamic group."
  }

  assert {
    condition     = alltrue([for dg in values(oci_identity_dynamic_group.this) : dg.compartment_id == var.tenancy_id])
    error_message = "Dynamic groups must be created at the tenancy root."
  }

  assert {
    condition     = oci_identity_dynamic_group.this["app-instances"].name == "app-instances" && oci_identity_dynamic_group.this["app-instances"].matching_rule == "ALL {instance.compartment.id = 'ocid1.compartment.oc1..aaaaaaaaexamplecompartment'}"
    error_message = "Name and matching rule should reach the resource."
  }

  assert {
    condition     = oci_identity_dynamic_group.this["fn.workers"].description == "Managed by Terraform"
    error_message = "description should default to \"Managed by Terraform\"."
  }

  assert {
    condition     = output.dynamic_group_ids["app-instances"] == oci_identity_dynamic_group.this["app-instances"].id && length(output.dynamic_group_ids) == 2
    error_message = "dynamic_group_ids should map every dynamic group name to its OCID."
  }

  assert {
    condition     = length(local.unreferenced_dynamic_groups) == 0
    error_message = "Both dynamic groups are named in a comma-separated subject and should count as referenced."
  }
}

run "accepts_spaced_dynamic_group_subject" {
  command = plan

  variables {
    dynamic_groups = {
      VolumeWriters = { matching_rule = "ALL {instance.compartment.id = 'ocid1.compartment.oc1..aaaaaaaaexamplecompartment'}" }
    }
    statements = [
      "Allow group example-readers to read all-resources in compartment id ocid1.compartment.oc1..aaaaaaaaexamplecompartment",
      "Allow dynamic group VolumeWriters to use key-delegate in compartment id ocid1.compartment.oc1..aaaaaaaaexamplecompartment",
    ]
  }

  assert {
    condition     = length(local.unreferenced_dynamic_groups) == 0
    error_message = "\"dynamic group <name>\" should count as a reference."
  }
}

run "warns_when_a_dynamic_group_is_not_referenced" {
  command = plan

  variables {
    dynamic_groups = {
      app-instances = { matching_rule = "ALL {instance.compartment.id = 'ocid1.compartment.oc1..aaaaaaaaexamplecompartment'}" }
    }
    # "app-instance" is a prefix of the real name and must not count.
    statements = [
      "Allow group example-readers to read all-resources in compartment id ocid1.compartment.oc1..aaaaaaaaexamplecompartment",
      "Allow dynamic-group app-instance to read secret-family in compartment id ocid1.compartment.oc1..aaaaaaaaexamplecompartment",
    ]
  }

  expect_failures = [check.policy_references_managed_dynamic_groups]
}

run "rejects_invalid_dynamic_group_name" {
  command = plan

  variables {
    dynamic_groups = {
      "app instances" = { matching_rule = "ALL {instance.compartment.id = 'ocid1.compartment.oc1..x'}" }
    }
  }

  expect_failures = [var.dynamic_groups]
}

run "rejects_empty_matching_rule" {
  command = plan

  variables {
    dynamic_groups = {
      app-instances = { matching_rule = "  " }
    }
  }

  expect_failures = [var.dynamic_groups]
}

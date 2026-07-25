# terraform-oci-iam

Terraform module that manages an [Oracle Cloud Infrastructure](https://www.oracle.com/cloud/)
IAM group together with a policy that grants it permissions. Groups are created at the
tenancy level; the policy can be attached to any compartment (or the tenancy) via its
statements.

## Usage

```hcl
module "iam" {
  source = "github.com/moveeeax/terraform-oci-iam"

  compartment_id = var.compartment_id
  tenancy_id     = var.tenancy_id
  group_name     = "network-admins"
  policy_name    = "network-admins-policy"

  statements = [
    "Allow group network-admins to manage virtual-network-family in compartment id ${var.compartment_id}"
  ]

  freeform_tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

A runnable example lives in [`examples/basic`](examples/basic).

## Policy statement guardrails

OCI policy statements are free-form strings — the provider forwards them verbatim,
so a typo is only caught by the service at apply time, and an over-broad statement
is never caught at all. This module checks the statements you pass before anything
is created.

**Rejected at `terraform plan` — statement syntax**

| Problem | Example |
|---------|---------|
| Unknown leading verb | `Alow group readers to read all-resources in tenancy` |
| Missing permission verb | `Allow group readers to all-resources in tenancy` |
| Missing scope | `Allow group readers to manage buckets` |

**Rejected at `terraform plan` unless `allow_privileged_statements = true`**

| Problem | Example |
|---------|---------|
| Wildcard subject/scope with no `where` condition | `Allow any-user to use api-keys in tenancy` |
| Cross-tenancy wildcard with no `where` condition | `Admit any-user of any-tenancy to read buckets in compartment id ...` |
| Tenancy-wide administrator | `Allow group readers to manage all-resources in tenancy` |

`any-user`, `any-group` and `any-tenancy` without a `where` clause are the OCI
analogue of an AWS trust policy with `Principal: "*"` and no condition: every
principal that can reach the policy gets the grant. Adding a `where` condition —
`... in tenancy where target.user.id = request.user.id` — clears the guard.
Compartment-scoped `manage all-resources` is a normal delegation pattern and is
**not** flagged; only `in tenancy` is.

To create a deliberately privileged group (a tenancy administrator, a cross-tenancy
delegation), set the escape hatch explicitly so the intent is visible in code review:

```hcl
module "tenancy_admins" {
  source = "github.com/moveeeax/terraform-oci-iam"

  compartment_id = var.tenancy_id
  tenancy_id     = var.tenancy_id
  group_name     = "tenancy-admins"
  policy_name    = "tenancy-admins-policy"

  allow_privileged_statements = true

  statements = [
    "Allow group tenancy-admins to manage all-resources in tenancy"
  ]
}
```

**Warning only**

If no statement mentions `group <group_name>`, the module emits a
[check](https://developer.hashicorp.com/terraform/language/checks) warning: the
group is being created with nothing attached to it, which usually means the group
name is misspelled in the statement. OCI happily accepts a statement naming a group
that does not exist, so this failure mode is otherwise silent.

## Requirements

| Name      | Version  |
|-----------|----------|
| terraform | >= 1.5   |
| oci       | >= 5.0   |

## Inputs

| Name                | Description                                                     | Type           | Default                   | Required |
|---------------------|-----------------------------------------------------------------|----------------|---------------------------|:--------:|
| `compartment_id`    | OCID of the compartment (or tenancy) the policy applies to.     | `string`       | n/a                       |   yes    |
| `tenancy_id`        | OCID of the tenancy in which to create the group.               | `string`       | n/a                       |   yes    |
| `group_name`        | Name of the IAM group to create.                                | `string`       | n/a                       |   yes    |
| `group_description` | Description of the IAM group.                                    | `string`       | `"Managed by Terraform"`  |    no    |
| `policy_name`       | Name of the IAM policy to create.                               | `string`       | n/a                       |   yes    |
| `policy_description`| Description of the IAM policy.                                   | `string`       | `"Managed by Terraform"`  |    no    |
| `statements`        | List of IAM policy statements. Validated — see [guardrails](#policy-statement-guardrails). | `list(string)` | n/a  |   yes    |
| `allow_privileged_statements` | Opt in to wildcard-subject or tenancy-wide-admin statements.  | `bool`         | `false`                   |    no    |
| `freeform_tags`     | Free-form tags applied to the group and policy.                 | `map(string)`  | `{}`                      |    no    |
| `defined_tags`      | Defined tags applied to the group and policy.                   | `map(string)`  | `{}`                      |    no    |

## Outputs

| Name         | Description                    |
|--------------|--------------------------------|
| `group_id`   | OCID of the IAM group.         |
| `group_name` | Name of the IAM group.         |
| `policy_id`  | OCID of the IAM policy.        |
| `statements` | Policy statements applied.     |

## Testing

The suite in [`tests/`](tests) runs against a mocked OCI provider — no credentials,
no network, no resources created:

```sh
terraform init -backend=false
terraform test
```

`mock_provider` requires Terraform (or OpenTofu) >= 1.7. That is a test-only
requirement; the module itself still supports >= 1.5.

## License

[MIT](LICENSE)

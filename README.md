# terraform-oci-iam

Terraform module that manages an [Oracle Cloud Infrastructure](https://www.oracle.com/cloud/)
IAM group together with a policy that grants it permissions. Groups are created at the
tenancy level; the policy can be attached to any compartment (or the tenancy) via its
statements.

## Usage

```hcl
module "iam" {
  source = "github.com/cybercapybara/terraform-oci-iam"

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
| `statements`        | List of IAM policy statements.                                  | `list(string)` | n/a                       |   yes    |
| `freeform_tags`     | Free-form tags applied to the group and policy.                 | `map(string)`  | `{}`                      |    no    |
| `defined_tags`      | Defined tags applied to the group and policy.                   | `map(string)`  | `{}`                      |    no    |

## Outputs

| Name         | Description                    |
|--------------|--------------------------------|
| `group_id`   | OCID of the IAM group.         |
| `group_name` | Name of the IAM group.         |
| `policy_id`  | OCID of the IAM policy.        |
| `statements` | Policy statements applied.     |

## License

[MIT](LICENSE)

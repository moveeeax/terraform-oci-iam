variable "compartment_id" {
  description = "OCID of the compartment (or tenancy) the policy applies to."
  type        = string
}

variable "tenancy_id" {
  description = "OCID of the tenancy in which to create the group. Groups always live at the tenancy level."
  type        = string
}

variable "group_name" {
  description = "Name of the IAM group to create."
  type        = string
}

variable "group_description" {
  description = "Description of the IAM group."
  type        = string
  default     = "Managed by Terraform"
}

variable "policy_name" {
  description = "Name of the IAM policy to create."
  type        = string
}

variable "policy_description" {
  description = "Description of the IAM policy."
  type        = string
  default     = "Managed by Terraform"
}

variable "statements" {
  description = <<-EOT
    List of IAM policy statements granting the group permissions.

    OCI policy statements are free-form strings: the provider forwards them verbatim
    and a typo is only rejected by the service at apply time (or, worse, silently
    produces a policy that grants nothing). The validations below catch the common
    shapes of that mistake before an apply is attempted.
  EOT
  type        = list(string)

  validation {
    condition     = length(var.statements) > 0
    error_message = "At least one policy statement must be provided."
  }

  # Every statement must start with one of the four OCI policy verbs. Catches
  # typos ("Alow group ...") and stray blank/comment lines.
  validation {
    condition = alltrue([
      for s in var.statements : can(regex("(?i)^\\s*(allow|endorse|admit|define)\\s", s))
    ])
    error_message = "Every policy statement must begin with Allow, Endorse, Admit or Define. Offending statements: ${join(" | ", [for s in var.statements : s if !can(regex("(?i)^\\s*(allow|endorse|admit|define)\\s", s))])}"
  }

  # Allow statements must be "Allow <subject> to <verb> <resource-type> in <scope>".
  # A statement missing the permission verb or the scope is accepted by Terraform
  # but rejected — or misinterpreted — by OCI.
  validation {
    condition = alltrue([
      for s in var.statements :
      !can(regex("(?i)^\\s*allow\\s", s)) ||
      can(regex("(?i)^\\s*allow\\s+.+\\s+to\\s+(inspect|read|use|manage)\\s+.+\\s+in\\s+(tenancy|compartment)\\b", s))
    ])
    error_message = "Allow statements must read \"Allow <subject> to <inspect|read|use|manage> <resource-type> in <tenancy|compartment ...>\". Offending statements: ${join(" | ", [for s in var.statements : s if can(regex("(?i)^\\s*allow\\s", s)) && !can(regex("(?i)^\\s*allow\\s+.+\\s+to\\s+(inspect|read|use|manage)\\s+.+\\s+in\\s+(tenancy|compartment)\\b", s))])}"
  }
}

variable "allow_privileged_statements" {
  description = <<-EOT
    Opt in to deliberately privileged policy statements. When false (the default) the
    module fails at plan time on:

      * wildcard subjects or scopes — `any-user`, `any-group`, `any-tenancy` — that
        carry no `where` condition, the OCI equivalent of a trust policy with a
        wildcard principal;
      * tenancy-wide `manage all-resources`, i.e. full tenancy administrator.

    Set to true only when the broad grant is intentional and has been reviewed.
  EOT
  type        = bool
  default     = false
}

variable "freeform_tags" {
  description = "Free-form tags applied to the group and policy."
  type        = map(string)
  default     = {}
}

variable "defined_tags" {
  description = "Defined tags applied to the group and policy, keyed as \"namespace.key\"."
  type        = map(string)
  default     = {}
}

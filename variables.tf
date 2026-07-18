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
  description = "List of IAM policy statements granting the group permissions."
  type        = list(string)

  validation {
    condition     = length(var.statements) > 0
    error_message = "At least one policy statement must be provided."
  }
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

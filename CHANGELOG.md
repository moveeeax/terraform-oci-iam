# Changelog

All notable changes to this module are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses
[Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- `dynamic_groups` input (default `{}`): dynamic groups keyed by name with a
  `matching_rule` and optional `description`, created at the tenancy level as
  `oci_identity_dynamic_group`. Names and non-empty rules are validated.
- `dynamic_group_ids` output, keyed by name.
- A check that warns when a managed dynamic group is not named in any statement as
  `dynamic-group <name>`.

[Unreleased]: https://github.com/moveeeax/terraform-oci-iam/compare/v1.1.0...HEAD

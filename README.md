# terraform-azurerm-template
Template file for creating public terraform modules which can be pushed to the Terraform registry

## Testing

Modules created from this template are tested with Terraform and OpenTofu in GitHub Actions on every pull request to any target branch, including documentation-only changes. Pushes to `main` run the checks when Terraform or test-related files change.
The workflow calls the shared workflow in [miljodir/workflow-templates](https://github.com/miljodir/workflow-templates). The starter smoke test needs no provider; tests that need one can use mocks and avoid Azure credentials. See [TESTING.md](TESTING.md).

## Release automation

The release workflow handles pull requests targeting `main` that change `**.tf`.
Opened, synchronized, reopened, labeled and unlabeled events refresh the release
preview. A merged `closed` event uses the shared
`generate-release-metadata/v1` workflow to dispatch release and wiki updates;
an unmerged close is skipped. The existing `create_release` and `update_wiki`
repository dispatch handlers remain separate from pull request processing.
Workflow-only changes do not match the Terraform path filter and do not release
the module.

Use exactly one release label (`patch`, `minor`, `major` or `no-release`).
`no-release` suppresses release and wiki dispatches. Public-fork pull requests
receive a read-only token: preview comments and release/wiki dispatches that
require write access can fail, including on merged close events. Fork releases
are not supported by this workflow; it does not use a privileged event or token
to bypass that restriction.

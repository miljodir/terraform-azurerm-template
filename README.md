# terraform-azurerm-template
Template file for creating public terraform modules which can be pushed to the Terraform registry

## Testing

Modules created from this template are tested with Terraform and OpenTofu in GitHub Actions on every pull request to any target branch, including documentation-only changes. Pushes to `main` run the checks when Terraform or test-related files change.
The workflow calls the shared workflow in [miljodir/workflow-templates](https://github.com/miljodir/workflow-templates). The starter smoke test needs no provider; tests that need one can use mocks and avoid Azure credentials. See [TESTING.md](TESTING.md).

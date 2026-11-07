# terraform-azurerm-template
Template file for creating public terraform modules which can be pushed to the Terraform registry

## Testing

Modules created from this template are tested with Terraform and OpenTofu in GitHub Actions on pull requests to any target branch and pushes to `main`.
The workflow calls the shared workflow in [miljodir/workflow-templates](https://github.com/miljodir/workflow-templates). Tests live in `tests/` and use mocked providers, so they need no Azure credentials. See [TESTING.md](TESTING.md).

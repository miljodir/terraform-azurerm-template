# terraform-azurerm-template
Template file for creating public terraform modules which can be pushed to the Terraform registry

## Testing

Modules created from this template are tested with `terraform test` in GitHub Actions on every pull request.
Tests live in `tests/` and use mocked providers, so they need no Azure credentials. See [TESTING.md](TESTING.md).

# Testing

This module is tested with the native [`terraform test`](https://developer.hashicorp.com/terraform/language/tests)
framework using both Terraform and OpenTofu. Tests run automatically in
GitHub Actions on pull requests to any target branch and pushes to `main`
(see `.github/workflows/terraform-test.yaml`).

## What runs in CI

The caller workflow uses the versioned shared workflow
[`miljodir/workflow-templates/.github/workflows/terraform-test.yaml@terraform-test/v0`](https://github.com/miljodir/workflow-templates/blob/terraform-test/v0/.github/workflows/terraform-test.yaml)
with `engine: both`. It runs the following checks independently with each
engine, and requires at least one test run to pass:

| Commands | Purpose |
| -------- | ------- |
| `terraform` / `tofu fmt -check -recursive` | Consistent formatting |
| `init -backend=false` and `validate` | Syntax, types and references are valid |
| `test` | Module behaviour (defaults, wiring, validation) |

## How the tests work

- Test files live in `tests/` and end in `.tftest.hcl`.
- Every test file declares `mock_provider` blocks. Mocked providers never call
  Azure: no credentials are needed and **no real resources are created**.
  Resource attributes that Azure would compute (for example `id`) get generated
  fake values.
- Each `run` block plans (`command = plan`) or "applies" against the mocks
  (`command = apply`) with a set of input variables, then checks the result with
  `assert` blocks.
- Input validation is tested with `expect_failures`, which passes only when the
  listed variable validation or precondition fails.
- Data sources and nested modules that would need real lookups can be replaced
  with `override_data` / `override_module`.

- When tests run, the module is the *root* module. Terraform then rejects
  outputs that contain sensitive attributes unless they are marked
  `sensitive = true` (consumers calling the module are not affected). Put
  test-only override files in `tests/overrides/` named `*_override.tf`, e.g.

  ```hcl
  output "storage_account" {
    sensitive = true
  }
  ```

  CI copies them into the module root before testing. Terraform validates the
  original outputs first; OpenTofu validates with the test-only overrides.

These are unit-style tests: they verify how the module turns inputs into
resource configuration. They do not prove that Azure accepts the configuration;
that still happens when a consuming workload runs `terraform plan`/`apply`.

## Writing a test

```hcl
mock_provider "azurerm" {}

variables {
  resource_group_name = "rg-test"
}

run "defaults" {
  command = plan

  assert {
    condition     = azurerm_example.this.name == "expected"
    error_message = "Name should default to 'expected'."
  }
}

run "rejects_invalid_input" {
  command = plan

  variables {
    some_setting = "not-allowed"
  }

  expect_failures = [var.some_setting]
}
```

Guidelines:

- Add or update a test whenever you change behaviour, defaults or validation.
- Use obviously fake values (`rg-test`, `00000000-0000-0000-0000-000000000000`,
  documentation IP ranges such as `192.0.2.0/24`). Never use real subscription
  IDs, tenant IDs, names or addresses — this repository is public.
- Prefer one behaviour per `run` block with a descriptive name.

## Running locally

Terraform's mocked-provider test framework requires Terraform >= 1.7.
OpenTofu has a compatible native test command; verify the module with each
engine you intend to support. Passing on one engine does not guarantee
compatibility with the other.

```sh
terraform init -backend=false
terraform validate
terraform test            # all tests
terraform test -verbose   # include plan output
terraform test -filter=tests/defaults.tftest.hcl
```

The equivalent commands for OpenTofu use `tofu`:

```sh
tofu init -backend=false
tofu validate
tofu test
```

Remove the copied `*_override.tf` files afterwards (they are git-ignored).

If the module references internal modules over SSH, you need SSH access to
GitHub for `terraform init` to download them.

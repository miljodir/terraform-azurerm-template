# Testing

This module is tested with the native [`terraform test`](https://developer.hashicorp.com/terraform/language/tests)
framework using both Terraform and OpenTofu. Tests run automatically in
GitHub Actions on every pull request to any target branch, including
documentation-only changes. Pushes to `main` run when Terraform or test-related
files change; the workflow can also be started manually
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

Some CLI versions can exit successfully when a test filter matches no files.
That is not a passing test: confirm the output reports at least one passed run.
The shared workflow enforces this for CI.

The testing scaffold does not add a root `required_version` or provider version
constraint. Keep compatibility ranges specific to each module; the CI tool
versions do not define the versions available to module consumers.

## How the tests work

- Test files live in `tests/` and end in `.tftest.hcl`.
- The starter smoke test needs no provider. When a test uses a provider, declare
  it with `mock_provider`; mocked providers never call Azure, need no credentials,
  and **do not create real resources**. Resource attributes Azure would compute
  (for example `id`) get generated fake values.
- Each `run` block plans (`command = plan`) or applies (`command = apply`) with
  its input variables, then checks the result with `assert` blocks.
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
terraform test -filter=tests\module.tftest.hcl
```

The equivalent commands for OpenTofu use `tofu`:

```sh
tofu init -backend=false
tofu validate
tofu test
tofu test -filter=tests\module.tftest.hcl
```

The examples above use Windows path separators. In Bash, Linux, and macOS
terminals, use `tests/module.tftest.hcl` in both `-filter` arguments instead.
Filtered test commands should print `Success! 1 passed, 0 failed` for the
starter smoke test.

Remove the copied `*_override.tf` files afterwards (they are git-ignored).

If the module references internal modules over SSH, you need SSH access to
GitHub for `terraform init` to download them.

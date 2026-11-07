# Example test file. Replace the run blocks below with tests for the module.
# See TESTING.md for guidance.

mock_provider "azurerm" {}

run "module_plans_with_defaults" {
  command = plan
}

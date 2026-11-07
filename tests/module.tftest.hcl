# Smoke test for the empty module template. Add provider mocks when adding
# resources or data sources.
# See TESTING.md for guidance.

run "module_plans_with_defaults" {
  command = plan
}

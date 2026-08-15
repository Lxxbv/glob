// Tests for literal-prefix traversal planning and safe fallback behavior.

///|
test "traversal plan extracts a directory prefix for recursive patterns" {
  let plan = @glob.TraversalPlan::from_pattern("src/**/*.mbt").unwrap()
  assert_eq(plan.root_prefix, "src")
  assert_true(plan.is_prunable())
  assert_true(plan.can_descend("src"))
  assert_true(plan.can_descend("src/core"))
  assert_true(!plan.can_descend("docs"))
  assert_true(plan.describe().contains("prefix=src"))
}

///|
test "traversal plan keeps a broad root when no directory is statically known" {
  let broad = @glob.TraversalPlan::from_pattern("**/*.mbt").unwrap()
  assert_eq(broad.root_prefix, "")
  assert_true(!broad.is_prunable())
  assert_true(broad.can_descend("src"))
  let exact = @glob.TraversalPlan::from_pattern("README.md").unwrap()
  assert_eq(exact.root_prefix, "")
  assert_true(exact.is_literal())
}

///|
test "traversal plan rejects invalid syntax before touching the filesystem" {
  match @glob.TraversalPlan::from_pattern("[z-a]") {
    Err(@glob.GlobError::InvalidRange) => ()
    _ => fail("invalid pattern should fail during planning")
  }
}

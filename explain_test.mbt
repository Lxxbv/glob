// Tests for diagnostics that make pattern behavior auditable in CI and CLIs.

///|
test "pattern explanation exposes tokens statistics and a safe recommendation" {
  let explanation = @glob.explain_pattern("src/{lib,test}/**/*.mbt").unwrap()
  assert_eq(explanation.normalized, "src/{lib,test}/**/*.mbt")
  assert_true(explanation.tokens.length() > 5)
  assert_eq(explanation.literal_prefix, "src/")
  assert_true(explanation.stats.globstar_count == 1)
  assert_true(explanation.stats.brace_group_count == 1)
  assert_eq(explanation.risk_name(), "recursive")
  assert_true(explanation.recommendation().contains("prefix"))
}

///|
test "pattern explanation distinguishes literals bounded patterns and invalid input" {
  let literal = @glob.explain_pattern("README.md").unwrap()
  assert_true(literal.is_literal())
  assert_eq(literal.complexity_score(), 0)
  assert_eq(literal.risk_name(), "literal")
  let bounded = @glob.explain_pattern("src/*.mbt").unwrap()
  assert_true(!bounded.is_literal())
  assert_eq(bounded.risk_name(), "bounded")
  match @glob.explain_pattern("[z-a]") {
    Err(@glob.GlobError::InvalidRange) => ()
    _ => fail("invalid pattern should be reported")
  }
}

///|
test "pattern explanation renders a stable AST signature" {
  let explanation = @glob.explain_pattern("a{b,c}?.txt").unwrap()
  assert_true(explanation.ast_text.contains("Brace"))
  assert_true(explanation.ast_text.contains("Question"))
  assert_true(explanation.signature().has_prefix("glob:v1:"))
}

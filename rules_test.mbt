// Tests for ignore-file compatible rule evaluation.

///|
test "rules support comments blank lines negation and last match wins" {
  let rules = @glob.GlobRules::from_lines([
    "# generated files", "", "*.tmp", "!keep.tmp", "/build/", "!build/keep.txt",
  ]).unwrap()
  assert_eq(rules.rule_count(), 4)
  assert_true(!rules.allows("cache/data.tmp", false))
  assert_true(rules.allows("keep.tmp", false))
  assert_true(!rules.allows("build/output.o", true))
  assert_true(rules.allows("build/keep.txt", false))
}

///|
test "rules distinguish anchored and directory-only patterns" {
  let rules = @glob.GlobRules::from_text("/dist/\nlogs/*.log\n!logs/keep.log\n").unwrap()
  assert_true(!rules.allows("dist/app.js", true))
  assert_true(rules.allows("src/dist/app.js", false))
  assert_true(!rules.allows("logs/today.log", false))
  assert_true(rules.allows("logs/keep.log", false))
}

///|
test "rules expose a deterministic decision explanation" {
  let rules = @glob.GlobRules::from_lines(["*.tmp", "!important.tmp"]).unwrap()
  assert_true(rules.explain("important.tmp", false).contains("Included"))
  assert_true(rules.explain("cache.tmp", false).contains("Excluded"))
  assert_true(rules.explain("README.md", false).contains("Unmatched"))
  assert_true(rules.explain("cache.tmp", false).contains("Excluded"))
}

///|
test "rules reject invalid patterns while ignoring comments" {
  match @glob.GlobRules::from_lines(["# comment", "[z-a]"]) {
    Err(@glob.GlobError::InvalidRange) => ()
    _ => fail("invalid rule pattern must be reported")
  }
}

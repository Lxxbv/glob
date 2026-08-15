// Deterministic benchmark-data tests.  No network or generated files needed.

///|
test "default workload contains realistic source and generated trees" {
  let workload = @glob.build_default_workload()
  assert_eq(workload.name, "default")
  assert_true(workload.patterns.length() >= 8)
  assert_true(workload.paths.length() >= 100)
  assert_true(workload.paths.contains("src/module00.mbt"))
  assert_true(workload.paths.contains("generated/src/module00.gen.mbt"))
  let result = @glob.evaluate_workload(workload)
  assert_eq(result.invalid_patterns, 0)
  assert_true(result.matches > 0)
  assert_true(result.patterns_with_matches > 0)
  assert_true(result.summary().contains("default"))
}

///|
test "large workload scales independently from the matcher" {
  let workload = @glob.build_large_workload()
  assert_true(workload.paths.length() > 500)
  let result = @glob.evaluate_workload(workload)
  assert_eq(result.invalid_patterns, 0)
  assert_true(result.matches >= result.patterns_with_matches)
  assert_true(result.coverage_percent() > 0)
  assert_true(result.csv_header().contains("pattern_count"))
}

///|
test "workload builder rejects unsafe sizes and supports custom cases" {
  match @glob.build_workload(0, 4) {
    Err(@glob.WorkloadError::InvalidSize) => ()
    _ => fail("zero depth should be rejected")
  }
  let custom = @glob.build_workload(2, 3).unwrap()
  assert_true(custom.paths.length() > 20)
  assert_eq(custom.patterns.length(), 10)
}

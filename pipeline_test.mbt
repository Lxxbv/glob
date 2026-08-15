// Tests for the high-level cached filtering pipeline.

///|
test "pipeline composes includes excludes sorting and limits" {
  let pipeline = @glob.GlobPipeline::new(4)
    .unwrap()
    .include_pattern("src/**/*.mbt")
    .exclude_pattern("**/*_test.mbt")
    .sorted()
    .with_limit(2)
    .unwrap()
  let report = pipeline
    .run([
      "src/z.mbt", "src/a_test.mbt", "src/a.mbt", "src/b.mbt", "docs/readme.md",
    ])
    .unwrap()
  assert_eq(report.scanned, 5)
  assert_eq(report.included, 3)
  assert_eq(report.returned, 2)
  assert_true(report.truncated)
  assert_eq(report.results[0], "src/a.mbt")
  assert_eq(report.results[1], "src/z.mbt")
}

///|
test "pipeline defaults to all paths and reports cache reuse" {
  let pipeline = @glob.GlobPipeline::new(2).unwrap().exclude_pattern("**/*.tmp")
  let paths = ["a.txt", "b.md", "cache.tmp"]
  let (pipeline, first) = pipeline.run_with_cache(paths).unwrap()
  let (_, second) = pipeline.run_with_cache(paths).unwrap()
  assert_eq(first.included, 2)
  assert_eq(second.results.length(), 2)
  assert_true(second.cache_hits > first.cache_hits)
  assert_true(second.summary().contains("scanned=3"))
}

///|
test "pipeline rejects a negative result limit" {
  match @glob.GlobPipeline::new(2).unwrap().with_limit(-1) {
    Err(@glob.PipelineError::InvalidLimit) => ()
    _ => fail("negative limit should be rejected")
  }
}

// Black-box tests for composable include/exclude queries.

///|
test "query applies includes excludes hidden paths and stable ordering" {
  let query = @glob.GlobQuery::new()
    .include_pattern("src/**/*.mbt")
    .unwrap()
    .exclude_pattern("**/generated/**")
    .unwrap()
    .with_options(@glob.GlobOptions::default().without_hidden().sorted())
  let report = query.execute_paths([
    "src/z.mbt", "src/.cache.mbt", "src/generated/api.mbt", "src/a.mbt", "docs/readme.md",
  ])
  assert_eq(report.examined, 5)
  assert_eq(report.included, 2)
  assert_eq(report.excluded, 1)
  assert_eq(report.results.length(), 2)
  assert_eq(report.results[0], "src/a.mbt")
  assert_eq(report.results[1], "src/z.mbt")
}

///|
test "query supports limits and depth boundaries" {
  let query = @glob.GlobQuery::new()
    .include_pattern("**/*.mbt")
    .unwrap()
    .with_min_depth(2)
    .unwrap()
    .with_limit(2)
    .unwrap()
  let report = query.execute_paths([
    "main.mbt", "src/main.mbt", "src/core/parser.mbt", "tests/unit/a.mbt",
  ])
  assert_eq(report.results.length(), 2)
  assert_eq(report.results[0], "src/main.mbt")
  assert_eq(report.results[1], "src/core/parser.mbt")
  assert_true(report.truncated)
}

///|
test "query without includes behaves as an exclusion query" {
  let query = @glob.GlobQuery::new().exclude_pattern("**/*.tmp").unwrap()
  let report = query.execute_paths(["a.txt", "cache/a.tmp", "b.md"])
  assert_eq(report.results.length(), 2)
  assert_eq(report.results[0], "a.txt")
  assert_eq(report.results[1], "b.md")
}

///|
test "query rejects invalid numeric bounds" {
  match @glob.GlobQuery::new().with_limit(-1) {
    Err(@glob.GlobError::InvalidMaxDepth) => ()
    _ => fail("negative query limits must be rejected")
  }
}

///|
test "query reports support summaries and safe pagination" {
  let query = @glob.GlobQuery::new()
    .include_pattern("src/**/*.mbt")
    .unwrap()
    .sorted()
  let report = query.execute_paths(["src/z.mbt", "src/a.mbt", "docs/readme.md"])
  assert_true(report.has_results())
  assert_true(report.is_complete())
  let first_page = report.page(0, 1)
  let second_page = report.page(1, 4)
  assert_eq(first_page.length(), 1)
  assert_eq(first_page[0], "src/a.mbt")
  assert_eq(second_page.length(), 1)
  assert_eq(second_page[0], "src/z.mbt")
  assert_eq(report.page(-1, 2).length(), 0)
  assert_eq(report.page(0, 0).length(), 0)
  assert_eq(
    report.summary(),
    "examined=3,included=2,excluded=0,returned=2,truncated=false",
  )
}

///|
test "indexed query retains file and directory options" {
  let index = @glob.PathIndex::from_entries([
    @glob.PathRecord::directory("src"),
    @glob.PathRecord::file("src/main.mbt"),
    @glob.PathRecord::file("src/test.mbt"),
    @glob.PathRecord::directory("src/generated"),
    @glob.PathRecord::file("src/generated/api.mbt"),
  ])
  let query = @glob.GlobQuery::new()
    .include_pattern("src/**/*.mbt")
    .unwrap()
    .exclude_pattern("**/generated/**")
    .unwrap()
    .files_only()
    .sorted()
  let report = query.execute_index(index)
  assert_eq(report.examined, 5)
  assert_eq(report.included, 2)
  assert_eq(report.excluded, 1)
  assert_eq(report.results.length(), 2)
  assert_eq(report.results[0], "src/main.mbt")
  assert_eq(report.results[1], "src/test.mbt")
}

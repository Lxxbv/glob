///|
test "batch compilation preserves pattern order" {
  let compiled = @glob.compile_many(["*.mbt", "src/**/*.mbt", "file[0-9].txt"]).unwrap()
  assert_eq(compiled.length(), 3)
  assert_true(@glob.match_path(compiled[0], "main.mbt"))
  assert_true(@glob.match_path(compiled[1], "src/core/main.mbt"))
  assert_true(@glob.match_path(compiled[2], "file7.txt"))
}

///|
test "batch matching supports any and all" {
  let patterns = ["*.mbt", "*.json"]
  assert_true(@glob.match_any(patterns, "main.mbt").unwrap())
  assert_true(@glob.match_any(patterns, "config.json").unwrap())
  assert_true(!@glob.match_any(patterns, "README.md").unwrap())

  let shared = ["**/*.mbt", "*.mbt"]
  assert_true(@glob.match_all(shared, "main.mbt").unwrap())
  assert_true(!@glob.match_all(shared, "src/main.mbt").unwrap())
}

///|
test "compiled batch filtering returns a stable report" {
  let ast = @glob.compile("src/**/*.mbt").unwrap()
  let paths = ["src/main.mbt", "src/core/parser.mbt", "README.md"]
  let report = @glob.classify_paths(ast, paths)
  assert_eq(report.matched.length(), 2)
  assert_eq(report.matched[0], "src/main.mbt")
  assert_eq(report.matched[1], "src/core/parser.mbt")
  assert_eq(report.unmatched.length(), 1)
  assert_eq(report.unmatched[0], "README.md")
}

///|
test "batch APIs propagate the first invalid pattern" {
  match @glob.compile_many(["*.mbt", "[z-a]"]) {
    Err(@glob.GlobError::InvalidRange) => ()
    _ => fail("compile_many should reject invalid patterns")
  }
  match @glob.match_any(["ok", "a,b"], "ok") {
    Err(@glob.GlobError::UnexpectedComma) => ()
    _ => fail("match_any should propagate pattern errors")
  }
}

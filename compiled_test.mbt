// Acceptance tests for compile-once pattern reuse.

///|
test "compiled pattern exposes reusable metadata" {
  let result = @glob.compile_pattern("src/**/*.mbt")
  match result {
    Err(_) => fail("unexpected compile error")
    Ok(compiled) => {
      assert_eq(compiled.pattern(), "src/**/*.mbt")
      assert_true(compiled.has_magic())
      assert_true(compiled.has_recursive_wildcard())
      assert_eq(compiled.literal_prefix(), "src/")
      assert_eq(compiled.separator_count(), 2)
      assert_eq(compiled.segment_count(), 3)
      assert_true(compiled.matches("src/main.mbt"))
      assert_true(compiled.matches("src/core/parser.mbt"))
      assert_true(!compiled.matches("docs/readme.md"))
    }
  }
}

///|
test "compiled pattern preserves syntax errors" {
  match @glob.compile_pattern("src/[z-a].mbt") {
    Err(@glob.GlobError::InvalidRange) => ()
    _ => fail("invalid range should be reported by compile_pattern")
  }
}

///|
test "compiled pattern batch matching avoids reparsing" {
  let compiled = @glob.compile_patterns(["src/**/*.mbt", "docs/**/*.md"]).unwrap()
  assert_true(@glob.match_compiled_any(compiled, "docs/api/index.md"))
  assert_true(!@glob.match_compiled_all(compiled, "src/main.mbt"))
  let filtered = @glob.filter_compiled_patterns(compiled, [
    "src/main.mbt", "docs/api/index.md", "main.rs",
  ])
  assert_eq(filtered.length(), 2)
  assert_eq(filtered[0], "src/main.mbt")
  assert_eq(filtered[1], "docs/api/index.md")
}

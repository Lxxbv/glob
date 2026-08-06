///|
test "pattern info extracts literal prefixes" {
  assert_eq(@glob.literal_prefix("src/**/*.mbt").unwrap(), "src/")
  assert_eq(@glob.literal_prefix("README.md").unwrap(), "README.md")
  assert_eq(@glob.literal_prefix("*.mbt").unwrap(), "")
  assert_eq(@glob.literal_prefix("file\\*.txt").unwrap(), "file*.txt")
}

///|
test "pattern info validates and classifies paths" {
  assert_true(@glob.is_path_pattern("src/**/*.mbt").unwrap())
  assert_true(!@glob.is_path_pattern("README.md").unwrap())
  assert_true(@glob.has_recursive_wildcard("src/**/main.mbt").unwrap())
  assert_true(!@glob.has_recursive_wildcard("src/*.mbt").unwrap())
  assert_eq(@glob.separator_count("src/**/*.mbt").unwrap(), 2)
}

///|
test "pattern info splits static path segments" {
  assert_eq(@glob.static_segments("src/core/main.mbt").unwrap(), [
    "src", "core", "main.mbt",
  ])
  assert_eq(@glob.static_segments("src/*.mbt").unwrap(), ["src"])
  match @glob.static_segments("{a,b}.mbt") {
    Err(@glob.GlobError::NonLiteralSegment) => ()
    _ => fail("wildcard segments cannot be treated as static")
  }
}

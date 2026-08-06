///|
test "path utilities normalize separators" {
  assert_eq(
    @glob.normalize_path("src\\\\core\\\\main.mbt"),
    "src/core/main.mbt",
  )
  assert_eq(@glob.normalize_path("./src//main.mbt"), "src/main.mbt")
  assert_eq(@glob.path_depth("src/core/main.mbt"), 3)
}

///|
test "path utilities split names" {
  assert_eq(@glob.basename("src/core/main.mbt"), "main.mbt")
  assert_eq(@glob.dirname("src/core/main.mbt"), "src/core")
  assert_eq(@glob.extension("src/core/main.mbt"), Some("mbt"))
  assert_eq(@glob.extension("README"), None)
}

///|
test "path utilities detect hidden components" {
  assert_true(@glob.is_hidden_path(".git/config"))
  assert_true(@glob.is_hidden_path("src/.cache/file"))
  assert_true(!@glob.is_hidden_path("src/cache/file"))
}

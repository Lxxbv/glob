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
  match @glob.extension("src/core/main.mbt") {
    Some(extension) => assert_eq(extension, "mbt")
    None => fail("extension should be present")
  }
  match @glob.extension("README") {
    Some(_) => fail("README should not have an extension")
    None => ()
  }
}

///|
test "path utilities detect hidden components" {
  assert_true(@glob.is_hidden_path(".git/config"))
  assert_true(@glob.is_hidden_path("src/.cache/file"))
  assert_true(!@glob.is_hidden_path("src/cache/file"))
}

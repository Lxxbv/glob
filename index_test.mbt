// Tests for the in-memory path index used by build tools and file browsers.

///|
test "path index normalizes paths and records file metadata" {
  let index = @glob.PathIndex::new()
    .add_directory("./src\\")
    .add_file("src\\main.mbt")
    .add_file(".cache/result.bin")
  assert_eq(index.length(), 3)
  assert_true(index.contains("src/main.mbt"))
  assert_true(index.contains("./src/main.mbt"))
  let main = index.get("src/main.mbt").unwrap()
  assert_eq(main.depth, 2)
  assert_eq(main.basename, "main.mbt")
  match main.extension {
    Some(extension) => assert_eq(extension, "mbt")
    None => fail("file extension should be recorded")
  }
  assert_true(main.hidden == false)
}

///|
test "path index supports compiled queries and prefixes" {
  let index = @glob.PathIndex::from_entries([
    @glob.PathRecord::file("src/main.mbt"),
    @glob.PathRecord::file("src/parser.mbt"),
    @glob.PathRecord::file("src/readme.md"),
    @glob.PathRecord::directory("src/core"),
  ])
  let matched = index.query("src/**/*.mbt").unwrap()
  assert_eq(matched.length(), 2)
  assert_eq(matched[0].path, "src/main.mbt")
  assert_eq(matched[1].path, "src/parser.mbt")
  assert_eq(index.under("src").length(), 4)
  assert_eq(index.children("src").length(), 4)
}

///|
test "path index keeps deterministic statistics and can remove entries" {
  let index = @glob.PathIndex::from_entries([
    @glob.PathRecord::file("a.txt"),
    @glob.PathRecord::file(".env"),
    @glob.PathRecord::directory("build"),
    @glob.PathRecord::file("build/out.o"),
  ])
  let stats = index.stats()
  assert_eq(stats.total, 4)
  assert_eq(stats.files, 3)
  assert_eq(stats.directories, 1)
  assert_eq(stats.hidden, 1)
  assert_eq(stats.max_depth, 2)
  let removed = index.remove("build/out.o")
  assert_eq(removed.length(), 3)
  assert_true(!removed.contains("build/out.o"))
}

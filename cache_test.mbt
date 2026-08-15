// Tests for bounded compiled-pattern caching.

///|
test "pattern cache compiles once and records hits" {
  let cache = @glob.PatternCache::new(2).unwrap()
  let (cache, first) = cache.get_or_compile("src/**/*.mbt").unwrap()
  let (cache, second) = cache.get_or_compile("src/**/*.mbt").unwrap()
  assert_eq(first.pattern(), second.pattern())
  let stats = cache.stats()
  assert_eq(stats.entries, 1)
  assert_eq(stats.hits, 1)
  assert_eq(stats.misses, 1)
  assert_eq(stats.evictions, 0)
}

///|
test "pattern cache evicts the oldest entry at a bounded capacity" {
  let cache = @glob.PatternCache::new(2).unwrap()
  let (cache, _) = cache.get_or_compile("a/*.mbt").unwrap()
  let (cache, _) = cache.get_or_compile("b/*.mbt").unwrap()
  let (cache, _) = cache.get_or_compile("c/*.mbt").unwrap()
  assert_eq(cache.entries_count(), 2)
  assert_true(!cache.contains("a/*.mbt"))
  assert_true(cache.contains("b/*.mbt"))
  assert_true(cache.contains("c/*.mbt"))
  assert_eq(cache.stats().evictions, 1)
}

///|
test "pattern cache filters paths with any and all semantics" {
  let cache = @glob.PatternCache::new(4).unwrap()
  let paths = ["src/main.mbt", "src/readme.md", "tests/main_test.mbt"]
  let (cache, any) = cache
    .match_any(["src/**/*.mbt", "tests/**/*.mbt"], paths)
    .unwrap()
  assert_true(any)
  let (cache, all) = cache
    .match_all(["**/*.mbt", "src/**/*.mbt"], "src/main.mbt")
    .unwrap()
  assert_true(all)
  let (cache, filtered) = cache.filter("**/*.mbt", paths).unwrap()
  assert_eq(filtered.length(), 2)
  assert_true(cache.stats().hits > 0)
}

///|
test "pattern cache validates capacity and invalid patterns" {
  match @glob.PatternCache::new(0) {
    Err(@glob.CacheError::InvalidCapacity) => ()
    _ => fail("zero capacity should be rejected")
  }
  let cache = @glob.PatternCache::new(1).unwrap()
  match cache.get_or_compile("[z-a]") {
    Err(@glob.GlobError::InvalidRange) => ()
    _ => fail("invalid patterns must preserve parser errors")
  }
}

///|
test "pattern analysis counts syntax features" {
  let stats = @glob.analyze("src/*.{mbt,json}").unwrap()
  assert_eq(stats.literal_chars, 12)
  assert_eq(stats.star_count, 1)
  assert_eq(stats.globstar_count, 0)
  assert_eq(stats.question_count, 0)
  assert_eq(stats.char_class_count, 0)
  assert_eq(stats.brace_group_count, 1)
  assert_eq(stats.escaped_char_count, 0)
  assert_true(stats.has_magic())
  assert_true(!stats.is_literal())
}

///|
test "pattern analysis recognizes escaped literals" {
  let stats = @glob.analyze("file\\*.txt").unwrap()
  assert_eq(stats.literal_chars, 9)
  assert_eq(stats.escaped_char_count, 1)
  assert_true(stats.is_literal())
  assert_eq(stats.magic_count(), 0)
}

///|
test "pattern analysis reports invalid patterns" {
  let result = @glob.analyze("[z-a]")
  match result {
    Err(@glob.GlobError::InvalidRange) => ()
    _ => fail("analysis should use the compiler's syntax errors")
  }
}

///|
test "cli arguments skip the moon package name" {
  match cli_query(["moon-glob", "cmd/main", "glob*.mbt", "."]) {
    Some((pattern, dir)) => {
      assert_eq(pattern, "glob*.mbt")
      assert_eq(dir, ".")
    }
    None => fail("expected moon run arguments to be accepted")
  }
}

///|
test "cli arguments skip the compiled moon run program" {
  match cli_query(["node", "cmd/main/main.js", "glob*.mbt", "."]) {
    Some((pattern, dir)) => {
      assert_eq(pattern, "glob*.mbt")
      assert_eq(dir, ".")
    }
    None => fail("expected compiled moon run arguments to be accepted")
  }
}

///|
test "cli arguments work for a direct executable" {
  match cli_query(["moon-glob", "glob*.mbt", "."]) {
    Some((pattern, dir)) => {
      assert_eq(pattern, "glob*.mbt")
      assert_eq(dir, ".")
    }
    None => fail("expected direct executable arguments to be accepted")
  }
}

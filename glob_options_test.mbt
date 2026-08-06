///|
test "glob options select files and directories" {
  let files = @glob.GlobOptions::default().files_only()
  match @glob.glob_with_options(".", "cmd/**", files) {
    Ok(paths) =>
      for path in paths {
        assert_true(path.has_prefix("cmd/"))
        assert_true(path != "cmd/main")
      }
    Err(_) => fail("file search failed")
  }

  let dirs = @glob.GlobOptions::default().directories_only()
  match @glob.glob_with_options(".", "cmd/**", dirs) {
    Ok(paths) => {
      assert_true(paths.length() > 0)
      for path in paths {
        assert_eq(path, "cmd/main")
      }
    }
    Err(_) => fail("directory search failed")
  }
}

///|
test "glob options hide dot paths and limit depth" {
  let options = @glob.GlobOptions::default().without_hidden().sorted()
  match @glob.glob_with_options(".", "**", options) {
    Ok(paths) => {
      for path in paths {
        assert_true(!path.has_prefix("."))
      }
      for i in 1..<paths.length() {
        assert_true(paths[i - 1] <= paths[i])
      }
    }
    Err(_) => fail("hidden path search failed")
  }

  let shallow = @glob.GlobOptions::default().with_max_depth(1).unwrap()
  match @glob.glob_with_options(".", "**", shallow) {
    Ok(paths) =>
      for path in paths {
        assert_true(!path.contains("/"))
      }
    Err(_) => fail("depth-limited search failed")
  }
}

///|
test "glob options reject negative depth" {
  let result = @glob.GlobOptions::default().with_max_depth(-1)
  match result {
    Err(@glob.GlobError::InvalidMaxDepth) => ()
    _ => fail("negative max depth should be rejected")
  }
}

// Blackbox tests run against the package's public API.

///|
test "public api compile and match" {
  let result = @glob.match_pattern("src/**/*.mbt", "src/main.mbt")
  debug_inspect(result, content="Ok(true)")

  let result_err = @glob.match_pattern("src/[a-z.mbt", "src/main.mbt")
  debug_inspect(result_err, content="Err(UnclosedBracket)")
}

///|
test "public api brace matching" {
  let result = @glob.match_pattern("*.{mbt,json}", "main.mbt")
  debug_inspect(result, content="Ok(true)")

  let result2 = @glob.match_pattern("*.{mbt,json}", "main.json")
  debug_inspect(result2, content="Ok(true)")

  let result3 = @glob.match_pattern("*.{mbt,json}", "main.rs")
  debug_inspect(result3, content="Ok(false)")
}

///|
test "public api brace alternatives may be empty" {
  let empty = @glob.match_pattern("{,a}", "")
  debug_inspect(empty, content="Ok(true)")

  let value = @glob.match_pattern("{a,}", "a")
  debug_inspect(value, content="Ok(true)")
}

///|
test "public api filter" {
  let paths = [
    "src/main.mbt", "src/utils.rs", "docs/index.md", "src/core/parser.mbt",
  ]

  let result = @glob.filter("src/**/*.mbt", paths)
  debug_inspect(
    result,
    content=(
      #|Ok(["src/main.mbt", "src/core/parser.mbt"])
    ),
  )

  let result2 = @glob.filter("*.{mbt,rs}", paths)
  debug_inspect(result2, content="Ok([])")

  let result3 = @glob.filter("docs/*.md", paths)
  debug_inspect(
    result3,
    content=(
      #|Ok(["docs/index.md"])
    ),
  )
}

///|
test "public api glob filesystem search" {
  let result = @glob.glob(".", "cmd/**/*.mbt")
  match result {
    Ok(paths) => {
      paths.sort()
      debug_inspect(
        paths,
        content="[\"cmd/main/main.mbt\", \"cmd/main/main_wbtest.mbt\"]",
      )
    }
    Err(err) => fail("glob search failed: \{err}")
  }

  let result2 = @glob.glob(".", "glob*.mbt")
  match result2 {
    Ok(paths) => {
      paths.sort()
      debug_inspect(
        paths,
        content=(
          #|[
          #|  "glob.mbt",
          #|  "glob_test.mbt",
          #|  "glob_wbtest.mbt",
          #|  "glob_bench_test.mbt",
          #|  "glob_options_test.mbt",
          #|]
        ),
      )
    }
    Err(err) => fail("glob search failed: \{err}")
  }
}

///|
test "public api reports filesystem errors" {
  let result = @glob.glob("__glob_missing_directory_for_test__", "**/*.mbt")
  match result {
    Err(@glob.GlobError::FilesystemError(_)) => ()
    _ => fail("glob should report a missing directory")
  }
}

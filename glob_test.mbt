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

// Blackbox tests run against the package's public API.

test "public api compile and match" {
  let result = @glob.match_pattern("src/**/*.mbt", "src/main.mbt")
  inspect!(result, content="Ok(true)")

  let result_err = @glob.match_pattern("src/[a-z.mbt", "src/main.mbt")
  inspect!(result_err, content="Err(UnclosedBracket)")
}

test "public api brace matching" {
  let result = @glob.match_pattern("*.{mbt,json}", "main.mbt")
  inspect!(result, content="Ok(true)")

  let result2 = @glob.match_pattern("*.{mbt,json}", "main.json")
  inspect!(result2, content="Ok(true)")

  let result3 = @glob.match_pattern("*.{mbt,json}", "main.rs")
  inspect!(result3, content="Ok(false)")
}

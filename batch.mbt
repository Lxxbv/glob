// Batch APIs for build systems and path-indexing tools.

///|
/// Separates matched and unmatched paths without recompiling the AST.
pub(all) struct MatchReport {
  matched : Array[String]
  unmatched : Array[String]
} derive(Debug, Eq)

///|
/// Compiles patterns in input order and stops at the first invalid pattern.
pub fn compile_many(patterns : Array[String]) -> Result[Array[AST], GlobError] {
  let result : Array[AST] = []
  for pattern in patterns {
    match compile(pattern) {
      Ok(ast) => result.push(ast)
      Err(err) => return Err(err)
    }
  }
  Ok(result)
}

///|
/// Returns true when at least one pattern matches the path.
pub fn match_any(
  patterns : Array[String],
  path : String,
) -> Result[Bool, GlobError] {
  let compiled = compile_many(patterns)
  match compiled {
    Err(err) => Err(err)
    Ok(asts) => {
      let mut matched = false
      for ast in asts {
        if match_path(ast, path) {
          matched = true
        }
      }
      Ok(matched)
    }
  }
}

///|
/// Returns true only when every pattern matches the path.
pub fn match_all(
  patterns : Array[String],
  path : String,
) -> Result[Bool, GlobError] {
  match compile_many(patterns) {
    Err(err) => Err(err)
    Ok(asts) => {
      let mut matched = true
      for ast in asts {
        if !match_path(ast, path) {
          matched = false
        }
      }
      Ok(matched)
    }
  }
}

///|
/// Filters paths with a previously compiled pattern.
pub fn filter_compiled(ast : AST, paths : Array[String]) -> Array[String] {
  let result : Array[String] = []
  for path in paths {
    if match_path(ast, path) {
      result.push(path)
    }
  }
  result
}

///|
/// Filters out paths with a previously compiled pattern.
pub fn filter_not_compiled(ast : AST, paths : Array[String]) -> Array[String] {
  let result : Array[String] = []
  for path in paths {
    if !match_path(ast, path) {
      result.push(path)
    }
  }
  result
}

///|
/// Classifies a path list with one compiled pattern.
pub fn classify_paths(ast : AST, paths : Array[String]) -> MatchReport {
  {
    matched: filter_compiled(ast, paths),
    unmatched: filter_not_compiled(ast, paths),
  }
}

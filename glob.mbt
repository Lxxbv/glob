// Public API of the caassien/glob package.

/// Compiles a glob pattern string into an AST.
pub fn compile(pattern : String) -> Result[AST, GlobError] {
  match tokenize(pattern) {
    Ok(tokens) => parse(tokens)
    Err(err) => Err(err)
  }
}

/// Matches a path string against a glob pattern string.
pub fn match_pattern(pattern : String, path : String) -> Result[Bool, GlobError] {
  match compile(pattern) {
    Ok(ast) => Ok(match_path(ast, path))
    Err(err) => Err(err)
  }
}

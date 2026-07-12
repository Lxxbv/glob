// Public API of the caassien/glob package.

///|
/// Compiles a glob pattern string into an AST.
pub fn compile(pattern : String) -> Result[AST, GlobError] {
  match tokenize(pattern) {
    Ok(tokens) => parse(tokens)
    Err(err) => Err(err)
  }
}

///|
/// Matches a path string against a glob pattern string.
pub fn match_pattern(
  pattern : String,
  path : String,
) -> Result[Bool, GlobError] {
  match compile(pattern) {
    Ok(ast) => Ok(match_path(ast, path))
    Err(err) => Err(err)
  }
}

///|
/// Filters an array of paths, returning only those that match the glob pattern.
pub fn filter(
  pattern : String,
  paths : Array[String],
) -> Result[Array[String], GlobError] {
  match compile(pattern) {
    Ok(ast) => {
      let result = []
      for path in paths {
        if match_path(ast, path) {
          result.push(path)
        }
      }
      Ok(result)
    }
    Err(err) => Err(err)
  }
}

///|
/// Filters an array of paths, returning only those that do NOT match the glob pattern.
pub fn filter_not(
  pattern : String,
  paths : Array[String],
) -> Result[Array[String], GlobError] {
  match compile(pattern) {
    Ok(ast) => {
      let result = []
      for path in paths {
        if !match_path(ast, path) {
          result.push(path)
        }
      }
      Ok(result)
    }
    Err(err) => Err(err)
  }
}

///|
fn list_relative_paths(
  dir : String,
  prefix : String,
  result : Array[String],
) -> Unit raise @fs.IOError {
  let current_dir = if prefix.is_empty() { dir } else { dir + "/" + prefix }
  let entries = @fs.read_dir(current_dir)
  for entry in entries {
    let rel_path = if prefix.is_empty() { entry } else { prefix + "/" + entry }
    let full_path = dir + "/" + rel_path
    result.push(rel_path)
    try {
      if @fs.is_dir(full_path) {
        list_relative_paths(dir, rel_path, result)
      }
    } catch {
      _ => ()
    }
  }
}

///|
/// Searches the filesystem starting from `dir` for paths matching the glob `pattern`.
/// The returned paths are relative to `dir`.
pub fn glob(dir : String, pattern : String) -> Result[Array[String], GlobError] {
  match compile(pattern) {
    Ok(ast) => {
      let paths = []
      list_relative_paths(dir, "", paths) catch {
        _ => return Ok([])
      }
      let result = []
      for path in paths {
        if match_path(ast, path) {
          result.push(path)
        }
      }
      Ok(result)
    }
    Err(err) => Err(err)
  }
}

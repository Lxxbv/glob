// Public API of the Lxxbv/glob package.

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
fn filesystem_error(err : @fs.IOError) -> GlobError {
  GlobError::FilesystemError(err.to_repr().to_string())
}

///|
fn list_relative_paths(
  dir : String,
  prefix : String,
  result : Array[String],
  options : GlobOptions,
) -> Result[Unit, GlobError] {
  let current_dir = if prefix.is_empty() { dir } else { dir + "/" + prefix }
  let entries = @fs.read_dir(current_dir) catch {
    err => return Err(filesystem_error(err))
  }
  for entry in entries {
    let rel_path = if prefix.is_empty() { entry } else { prefix + "/" + entry }
    let full_path = dir + "/" + rel_path
    let is_directory = @fs.is_dir(full_path) catch {
      err => return Err(filesystem_error(err))
    }
    let is_hidden = is_hidden_path(rel_path)
    let depth = path_depth(rel_path)
    let within_depth = match options.max_depth {
      None => true
      Some(max_depth) => depth <= max_depth
    }
    if (!is_hidden || options.include_hidden) && within_depth {
      if (is_directory && options.include_directories) ||
        (!is_directory && options.include_files) {
        result.push(rel_path)
      }
    }
    let can_recurse = match options.max_depth {
      None => true
      Some(max_depth) => depth < max_depth
    }
    if is_directory && can_recurse && (!is_hidden || options.include_hidden) {
      match list_relative_paths(dir, rel_path, result, options) {
        Ok(_) => ()
        Err(err) => return Err(err)
      }
    }
  }
  Ok(())
}

///|
/// Searches the filesystem starting from `dir` for paths matching the glob `pattern`.
/// The returned paths are relative to `dir`.
pub fn glob(dir : String, pattern : String) -> Result[Array[String], GlobError] {
  glob_with_options(dir, pattern, GlobOptions::default())
}

///|
/// Searches the filesystem using explicit filtering and traversal options.
pub fn glob_with_options(
  dir : String,
  pattern : String,
  options : GlobOptions,
) -> Result[Array[String], GlobError] {
  match compile_pattern(pattern) {
    Ok(compiled) => {
      let plan = TraversalPlan::from_compiled(compiled)
      let paths = []
      let start_prefix = plan.start_prefix(dir)
      match list_relative_paths(dir, start_prefix, paths, options) {
        Ok(_) => ()
        Err(err) => return Err(err)
      }
      let result = []
      for path in paths {
        if plan.matches(path) {
          result.push(path)
        }
      }
      if options.sort_results {
        result.sort()
      }
      Ok(result)
    }
    Err(err) => Err(err)
  }
}

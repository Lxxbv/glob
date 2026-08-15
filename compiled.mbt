// Compile-once pattern handles for build tools, indexes, and repeated queries.

///|
/// A reusable compiled glob pattern with stable structural metadata.
pub(all) struct CompiledPattern {
  source : String
  ast : AST
  stats : PatternStats
  prefix : String
  separators : Int
  recursive : Bool
  segments : Int
} derive(Debug, Eq)

///|
fn compiled_segment_count(source : String) -> Int {
  let normalized = normalize_path(source)
  if normalized.is_empty() {
    0
  } else {
    let mut count = 1
    let mut i = 0
    while i < normalized.length() {
      if normalized[i].to_int().unsafe_to_char() == '/' {
        count = count + 1
      }
      i = i + 1
    }
    count
  }
}

///|
fn compiled_stats(pattern : String, ast : AST) -> PatternStats {
  { ..ast_stats(ast), escaped_char_count: count_escaped_chars(pattern) }
}

///|
/// Compiles one pattern and records metadata without changing matching rules.
pub fn compile_pattern(pattern : String) -> Result[CompiledPattern, GlobError] {
  match compile(pattern) {
    Err(err) => Err(err)
    Ok(ast) => {
      let prefix = literal_prefix(pattern)
      let separators = separator_count(pattern)
      let recursive = has_recursive_wildcard(pattern)
      match (prefix, separators, recursive) {
        (Ok(prefix), Ok(separators), Ok(recursive)) =>
          Ok({
            source: pattern,
            ast,
            stats: compiled_stats(pattern, ast),
            prefix,
            separators,
            recursive,
            segments: compiled_segment_count(pattern),
          })
        (Err(err), _, _) => Err(err)
        (_, Err(err), _) => Err(err)
        (_, _, Err(err)) => Err(err)
      }
    }
  }
}

///|
/// Compiles a batch while preserving the caller's pattern order.
pub fn compile_patterns(
  patterns : Array[String],
) -> Result[Array[CompiledPattern], GlobError] {
  let result : Array[CompiledPattern] = []
  for pattern in patterns {
    match compile_pattern(pattern) {
      Ok(compiled) => result.push(compiled)
      Err(err) => return Err(err)
    }
  }
  Ok(result)
}

///|
/// Returns the original source pattern.
pub fn CompiledPattern::pattern(self : CompiledPattern) -> String {
  self.source
}

///|
/// Returns the compiled syntax tree for advanced callers.
pub fn CompiledPattern::ast(self : CompiledPattern) -> AST {
  self.ast
}

///|
/// Returns structural pattern statistics captured at compile time.
pub fn CompiledPattern::stats(self : CompiledPattern) -> PatternStats {
  self.stats
}

///|
/// Returns the literal prefix before the first wildcard.
pub fn CompiledPattern::literal_prefix(self : CompiledPattern) -> String {
  self.prefix
}

///|
/// Returns the number of path separators in the source pattern.
pub fn CompiledPattern::separator_count(self : CompiledPattern) -> Int {
  self.separators
}

///|
/// Returns whether the pattern contains the recursive \\`**\\` construct.
pub fn CompiledPattern::has_recursive_wildcard(self : CompiledPattern) -> Bool {
  self.recursive
}

///|
/// Returns the number of non-empty source path components.
pub fn CompiledPattern::segment_count(self : CompiledPattern) -> Int {
  self.segments
}

///|
/// Matches one path without reparsing the source pattern.
pub fn CompiledPattern::matches(self : CompiledPattern, path : String) -> Bool {
  match_path(self.ast, normalize_path(path))
}

///|
/// Returns true when this handle has at least one wildcard construct.
pub fn CompiledPattern::has_magic(self : CompiledPattern) -> Bool {
  self.stats.has_magic()
}

///|
/// Returns true when this handle is a literal-only pattern.
pub fn CompiledPattern::is_literal(self : CompiledPattern) -> Bool {
  self.stats.is_literal()
}

///|
/// Estimates the number of matching branches exposed by the syntax tree.
pub fn CompiledPattern::estimated_branches(self : CompiledPattern) -> Int {
  let stats = self.stats
  let mut estimate = 1
  estimate = estimate + stats.star_count
  estimate = estimate + stats.globstar_count * 2
  estimate = estimate + stats.question_count
  estimate = estimate + stats.char_class_count
  estimate = estimate + stats.brace_group_count * 2
  estimate
}

///|
/// Returns a compact, deterministic metadata summary useful in logs.
pub fn CompiledPattern::summary(self : CompiledPattern) -> String {
  "pattern=" +
  self.source +
  ",prefix=" +
  self.prefix +
  ",segments=" +
  self.segments.to_string() +
  ",separators=" +
  self.separators.to_string() +
  ",magic=" +
  self.has_magic().to_string() +
  ",recursive=" +
  self.recursive.to_string() +
  ",branches=" +
  self.estimated_branches().to_string()
}

///|
/// Matches one path against any previously compiled pattern.
pub fn match_compiled_any(
  patterns : Array[CompiledPattern],
  path : String,
) -> Bool {
  for pattern in patterns {
    if pattern.matches(path) {
      return true
    }
  }
  false
}

///|
/// Matches one path against every previously compiled pattern.
pub fn match_compiled_all(
  patterns : Array[CompiledPattern],
  path : String,
) -> Bool {
  for pattern in patterns {
    if !pattern.matches(path) {
      return false
    }
  }
  true
}

///|
/// Filters a path list using compiled patterns and removes duplicate results.
pub fn filter_compiled_patterns(
  patterns : Array[CompiledPattern],
  paths : Array[String],
) -> Array[String] {
  let result : Array[String] = []
  for path in paths {
    let normalized = normalize_path(path)
    if match_compiled_any(patterns, normalized) && !result.contains(normalized) {
      result.push(normalized)
    }
  }
  result
}

///|
/// Returns the paths that match none of the compiled patterns.
pub fn filter_not_compiled_patterns(
  patterns : Array[CompiledPattern],
  paths : Array[String],
) -> Array[String] {
  let result : Array[String] = []
  for path in paths {
    let normalized = normalize_path(path)
    if !match_compiled_any(patterns, normalized) && !result.contains(normalized) {
      result.push(normalized)
    }
  }
  result
}

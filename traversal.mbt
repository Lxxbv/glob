// Filesystem traversal planning based on compiled literal prefixes.
//
// A matcher still validates every returned path.  The plan only narrows the
// initial directory when that directory is statically safe, and falls back to
// the repository root if the prefix is absent or points at a file.

///|
pub(all) struct TraversalPlan {
  pattern : CompiledPattern
  root_prefix : String
  recursive : Bool
  literal : Bool
} derive(Debug, Eq)

///|
fn trim_prefix_separator(prefix : String) -> String {
  let normalized = normalize_path(prefix)
  if normalized.has_suffix("/") {
    normalized[:normalized.length() - 1].to_owned()
  } else {
    normalized
  }
}

///|
fn static_root(prefix : String) -> String {
  let normalized = normalize_path(prefix)
  if normalized.is_empty() {
    ""
  } else if normalized.has_suffix("/") {
    trim_prefix_separator(normalized)
  } else {
    let parent = dirname(normalized)
    if parent == "." {
      ""
    } else {
      parent
    }
  }
}

///|
/// Builds a plan and compiles the pattern exactly once.
pub fn TraversalPlan::from_pattern(
  pattern : String,
) -> Result[TraversalPlan, GlobError] {
  match compile_pattern(pattern) {
    Err(err) => Err(err)
    Ok(compiled) => Ok(TraversalPlan::from_compiled(compiled))
  }
}

///|
pub fn TraversalPlan::from_compiled(pattern : CompiledPattern) -> TraversalPlan {
  {
    root_prefix: static_root(pattern.literal_prefix()),
    recursive: pattern.has_recursive_wildcard(),
    literal: pattern.is_literal(),
    pattern,
  }
}

///|
pub fn TraversalPlan::is_prunable(self : TraversalPlan) -> Bool {
  !self.root_prefix.is_empty()
}

///|
pub fn TraversalPlan::is_literal(self : TraversalPlan) -> Bool {
  self.literal
}

///|
pub fn TraversalPlan::is_recursive(self : TraversalPlan) -> Bool {
  self.recursive
}

///|
/// Returns whether a relative directory can contain a matching path.
pub fn TraversalPlan::can_descend(
  self : TraversalPlan,
  relative_path : String,
) -> Bool {
  if self.root_prefix.is_empty() {
    true
  } else {
    let normalized = trim_prefix_separator(relative_path)
    normalized == self.root_prefix ||
    normalized.has_prefix(self.root_prefix + "/")
  }
}

///|
/// Chooses a safe starting prefix when it exists on the filesystem.
pub fn TraversalPlan::start_prefix(
  self : TraversalPlan,
  dir : String,
) -> String {
  if self.root_prefix.is_empty() {
    ""
  } else {
    let candidate = dir + "/" + self.root_prefix
    let is_directory = @fs.is_dir(candidate) catch { _ => false }
    if is_directory {
      self.root_prefix
    } else {
      ""
    }
  }
}

///|
pub fn TraversalPlan::matches(self : TraversalPlan, path : String) -> Bool {
  self.pattern.matches(path)
}

///|
pub fn TraversalPlan::pattern(self : TraversalPlan) -> CompiledPattern {
  self.pattern
}

///|
/// Returns the number of static path components used for pruning.
pub fn TraversalPlan::prefix_depth(self : TraversalPlan) -> Int {
  path_depth(self.root_prefix)
}

///|
pub fn TraversalPlan::describe(self : TraversalPlan) -> String {
  "pattern=\"" +
  self.pattern.pattern() +
  "\" prefix=" +
  self.root_prefix +
  " recursive=" +
  self.recursive.to_string() +
  " literal=" +
  self.literal.to_string()
}

///|
/// Returns a simple estimate of how many directory levels can be skipped.
pub fn TraversalPlan::estimated_skipped_levels(
  self : TraversalPlan,
  current_depth : Int,
) -> Int {
  let prefix_depth = self.prefix_depth()
  if prefix_depth > current_depth {
    prefix_depth - current_depth
  } else {
    0
  }
}

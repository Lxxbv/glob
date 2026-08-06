// Search configuration for filesystem globbing.

///|
/// Controls which filesystem entries are returned by `glob_with_options`.
pub(all) struct GlobOptions {
  include_files : Bool
  include_directories : Bool
  include_hidden : Bool
  max_depth : Int?
  sort_results : Bool
} derive(Debug, Eq)

///|
/// Creates options compatible with the original `glob` behavior.
pub fn GlobOptions::default() -> GlobOptions {
  {
    include_files: true,
    include_directories: true,
    include_hidden: true,
    max_depth: None,
    sort_results: false,
  }
}

///|
/// Returns options that include files but not directories.
pub fn GlobOptions::files_only(self : GlobOptions) -> GlobOptions {
  { ..self, include_files: true, include_directories: false }
}

///|
/// Returns options that include directories but not files.
pub fn GlobOptions::directories_only(self : GlobOptions) -> GlobOptions {
  { ..self, include_files: false, include_directories: true }
}

///|
/// Returns options that skip hidden path components.
pub fn GlobOptions::without_hidden(self : GlobOptions) -> GlobOptions {
  { ..self, include_hidden: false }
}

///|
/// Returns options with deterministic lexicographic output ordering.
pub fn GlobOptions::sorted(self : GlobOptions) -> GlobOptions {
  { ..self, sort_results: true }
}

///|
/// Limits traversal to entries at or below the given relative depth.
pub fn GlobOptions::with_max_depth(
  self : GlobOptions,
  depth : Int,
) -> Result[GlobOptions, GlobError] {
  if depth < 0 {
    Err(GlobError::InvalidMaxDepth)
  } else {
    Ok({ ..self, max_depth: Some(depth) })
  }
}

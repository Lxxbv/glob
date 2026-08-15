// Deterministic, filesystem-independent workloads for benchmarks and QA.
//
// The data models common repositories: source files, tests, documentation,
// generated artifacts, hidden caches, and nested resources.  Keeping the
// generator in the library makes benchmark claims reproducible on every OS.

///|
pub enum WorkloadError {
  InvalidSize
  TooLarge
} derive(Debug, Eq)

///|
pub impl Show for WorkloadError with fn output(self, logger) {
  match self {
    WorkloadError::InvalidSize => logger.write_string("InvalidSize")
    WorkloadError::TooLarge => logger.write_string("TooLarge")
  }
}

///|
/// A named collection of patterns and deterministic candidate paths.
pub(all) struct GlobWorkload {
  name : String
  patterns : Array[String]
  paths : Array[String]
} derive(Debug, Eq)

///|
/// Aggregate results from evaluating every pattern against every candidate.
pub(all) struct WorkloadResult {
  workload_name : String
  pattern_count : Int
  path_count : Int
  matches : Int
  patterns_with_matches : Int
  invalid_patterns : Int
  literal_patterns : Int
  recursive_patterns : Int
} derive(Debug, Eq)

///|
fn two_digits(value : Int) -> String {
  if value < 10 {
    "0" + value.to_string()
  } else {
    value.to_string()
  }
}

///|
fn default_patterns() -> Array[String] {
  [
    "**/*.mbt", "**/*_test.mbt", "src/**/*.mbt", "tests/**/*.mbt", "docs/**/*.md",
    "**/*.json", "generated/**/*.gen.mbt", ".cache/**", "**/nested/*.txt", "**/missing/*.none",
  ]
}

///|
fn append_path_family(
  paths : Array[String],
  directory : String,
  index : Int,
  include_deep : Bool,
) -> Unit {
  let suffix = two_digits(index)
  paths.push(directory + "/module" + suffix + ".mbt")
  paths.push(directory + "/module" + suffix + "_test.mbt")
  paths.push(directory + "/data" + suffix + ".json")
  paths.push(directory + "/note" + suffix + ".md")
  paths.push("generated/" + directory + "/module" + suffix + ".gen.mbt")
  if include_deep {
    paths.push(directory + "/nested/leaf" + suffix + ".txt")
    paths.push(directory + "/nested/leaf" + suffix + ".bin")
  }
}

///|
fn build_paths(depth : Int, width : Int) -> Array[String] {
  let paths : Array[String] = [
    ".cache/index.bin", ".cache/state.json", "README.md", "LICENSE",
  ]
  let directories = ["src", "tests", "docs", "bench", "generated"]
  for directory in directories {
    let mut i = 0
    while i < width {
      append_path_family(paths, directory, i, depth > 1)
      i = i + 1
    }
  }
  paths
}

///|
/// Builds a reproducible repository-shaped workload.
pub fn build_workload(
  depth : Int,
  width : Int,
) -> Result[GlobWorkload, WorkloadError] {
  if depth < 1 || width < 1 {
    return Err(WorkloadError::InvalidSize)
  }
  if depth > 16 || width > 1000 {
    return Err(WorkloadError::TooLarge)
  }
  Ok({
    name: "custom-" + depth.to_string() + "x" + width.to_string(),
    patterns: default_patterns(),
    paths: build_paths(depth, width),
  })
}

///|
/// A compact workload suitable for every CI run.
pub fn build_default_workload() -> GlobWorkload {
  let workload = build_workload(3, 8).unwrap()
  { ..workload, name: "default" }
}

///|
/// A larger workload for local performance checks and release notes.
pub fn build_large_workload() -> GlobWorkload {
  let workload = build_workload(8, 40).unwrap()
  { ..workload, name: "large" }
}

///|
/// Returns the workload name.
pub fn GlobWorkload::name(self : GlobWorkload) -> String {
  self.name
}

///|
pub fn GlobWorkload::pattern_count(self : GlobWorkload) -> Int {
  self.patterns.length()
}

///|
pub fn GlobWorkload::path_count(self : GlobWorkload) -> Int {
  self.paths.length()
}

///|
pub fn GlobWorkload::patterns(self : GlobWorkload) -> Array[String] {
  self.patterns.copy()
}

///|
pub fn GlobWorkload::paths(self : GlobWorkload) -> Array[String] {
  self.paths.copy()
}

///|
/// Adds a path if it is not already present.
pub fn GlobWorkload::with_path(
  self : GlobWorkload,
  path : String,
) -> GlobWorkload {
  let paths = self.paths.copy()
  if !paths.contains(path) {
    paths.push(normalize_path(path))
  }
  { ..self, paths, }
}

///|
/// Adds a pattern while preserving input order.
pub fn GlobWorkload::with_pattern(
  self : GlobWorkload,
  pattern : String,
) -> GlobWorkload {
  let patterns = self.patterns.copy()
  patterns.push(pattern)
  { ..self, patterns, }
}

///|
fn evaluate_compiled(compiled : CompiledPattern, paths : Array[String]) -> Int {
  let mut matches = 0
  for path in paths {
    if compiled.matches(path) {
      matches = matches + 1
    }
  }
  matches
}

///|
/// Evaluates a workload with one compilation per pattern and no timing noise.
pub fn evaluate_workload(workload : GlobWorkload) -> WorkloadResult {
  let mut matches = 0
  let mut patterns_with_matches = 0
  let mut invalid_patterns = 0
  let mut literal_patterns = 0
  let mut recursive_patterns = 0
  for pattern in workload.patterns {
    match compile_pattern(pattern) {
      Err(_) => invalid_patterns = invalid_patterns + 1
      Ok(compiled) => {
        if compiled.is_literal() {
          literal_patterns = literal_patterns + 1
        }
        if compiled.has_recursive_wildcard() {
          recursive_patterns = recursive_patterns + 1
        }
        let count = evaluate_compiled(compiled, workload.paths)
        matches = matches + count
        if count > 0 {
          patterns_with_matches = patterns_with_matches + 1
        }
      }
    }
  }
  {
    workload_name: workload.name,
    pattern_count: workload.patterns.length(),
    path_count: workload.paths.length(),
    matches,
    patterns_with_matches,
    invalid_patterns,
    literal_patterns,
    recursive_patterns,
  }
}

///|
pub fn WorkloadResult::coverage_percent(self : WorkloadResult) -> Int {
  let total = self.pattern_count * self.path_count
  if total == 0 {
    0
  } else {
    self.matches * 100 / total
  }
}

///|
pub fn WorkloadResult::summary(self : WorkloadResult) -> String {
  "workload=" +
  self.workload_name +
  " patterns=" +
  self.pattern_count.to_string() +
  " paths=" +
  self.path_count.to_string() +
  " matches=" +
  self.matches.to_string() +
  " invalid=" +
  self.invalid_patterns.to_string()
}

///|
pub fn WorkloadResult::csv_header(_self : WorkloadResult) -> String {
  "workload_name,pattern_count,path_count,matches,patterns_with_matches,invalid_patterns"
}

///|
pub fn WorkloadResult::csv_row(self : WorkloadResult) -> String {
  self.workload_name +
  "," +
  self.pattern_count.to_string() +
  "," +
  self.path_count.to_string() +
  "," +
  self.matches.to_string() +
  "," +
  self.patterns_with_matches.to_string() +
  "," +
  self.invalid_patterns.to_string()
}

///|
pub fn WorkloadResult::has_invalid_patterns(self : WorkloadResult) -> Bool {
  self.invalid_patterns > 0
}

///|
pub fn WorkloadResult::is_useful(self : WorkloadResult) -> Bool {
  self.matches > 0 &&
  self.patterns_with_matches > 0 &&
  self.invalid_patterns == 0
}

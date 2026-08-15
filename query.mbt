// Composable path-query engine for build systems and source explorers.

///|
/// A report returned by a path query.
pub(all) struct QueryReport {
  examined : Int
  included : Int
  excluded : Int
  returned : Int
  truncated : Bool
  results : Array[String]
} derive(Debug, Eq)

///|
/// Returns whether the query produced at least one result.
pub fn QueryReport::has_results(self : QueryReport) -> Bool {
  self.returned > 0
}

///|
/// Returns whether the result set contains every accepted path.
pub fn QueryReport::is_complete(self : QueryReport) -> Bool {
  !self.truncated
}

///|
/// Returns the number of results in the current pageable report.
pub fn QueryReport::returned_count(self : QueryReport) -> Int {
  self.returned
}

///|
/// Returns a bounded page of results without changing the original report.
/// Invalid offsets and page sizes produce an empty page.
pub fn QueryReport::page(
  self : QueryReport,
  offset : Int,
  page_size : Int,
) -> Array[String] {
  let page : Array[String] = []
  if offset < 0 || page_size <= 0 || offset >= self.results.length() {
    return page
  }
  let end = if offset + page_size < self.results.length() {
    offset + page_size
  } else {
    self.results.length()
  }
  for i in offset..<end {
    page.push(self.results[i])
  }
  page
}

///|
/// Returns a compact summary suitable for build logs and diagnostics.
pub fn QueryReport::summary(self : QueryReport) -> String {
  "examined=" +
  self.examined.to_string() +
  ",included=" +
  self.included.to_string() +
  ",excluded=" +
  self.excluded.to_string() +
  ",returned=" +
  self.returned.to_string() +
  ",truncated=" +
  self.truncated.to_string()
}

///|
/// A reusable query with include rules, exclude rules, and result policies.
pub(all) struct GlobQuery {
  includes : Array[CompiledPattern]
  excludes : Array[CompiledPattern]
  options : GlobOptions
  min_depth : Int
  limit : Int?
} derive(Debug, Eq)

///|
pub fn GlobQuery::new() -> GlobQuery {
  {
    includes: [],
    excludes: [],
    options: GlobOptions::default(),
    min_depth: 0,
    limit: None,
  }
}

///|
/// Adds an include pattern. Multiple includes use OR semantics.
pub fn GlobQuery::include_pattern(
  self : GlobQuery,
  pattern : String,
) -> Result[GlobQuery, GlobError] {
  match compile_pattern(pattern) {
    Err(err) => Err(err)
    Ok(compiled) => {
      let includes = self.includes.copy()
      includes.push(compiled)
      Ok({ ..self, includes, })
    }
  }
}

///|
/// Adds an exclude pattern. Exclusions always take precedence.
pub fn GlobQuery::exclude_pattern(
  self : GlobQuery,
  pattern : String,
) -> Result[GlobQuery, GlobError] {
  match compile_pattern(pattern) {
    Err(err) => Err(err)
    Ok(compiled) => {
      let excludes = self.excludes.copy()
      excludes.push(compiled)
      Ok({ ..self, excludes, })
    }
  }
}

///|
/// Replaces traversal and result options.
pub fn GlobQuery::with_options(
  self : GlobQuery,
  options : GlobOptions,
) -> GlobQuery {
  { ..self, options, }
}

///|
/// Requires paths to have at least the given number of components.
pub fn GlobQuery::with_min_depth(
  self : GlobQuery,
  depth : Int,
) -> Result[GlobQuery, GlobError] {
  if depth < 0 {
    Err(GlobError::InvalidMaxDepth)
  } else {
    Ok({ ..self, min_depth: depth })
  }
}

///|
/// Limits the number of returned paths.
pub fn GlobQuery::with_limit(
  self : GlobQuery,
  limit : Int,
) -> Result[GlobQuery, GlobError] {
  if limit < 0 {
    Err(GlobError::InvalidMaxDepth)
  } else {
    Ok({ ..self, limit: Some(limit) })
  }
}

///|
/// Enables deterministic result ordering.
pub fn GlobQuery::sorted(self : GlobQuery) -> GlobQuery {
  { ..self, options: self.options.sorted() }
}

///|
/// Excludes hidden components from the result.
pub fn GlobQuery::without_hidden(self : GlobQuery) -> GlobQuery {
  { ..self, options: self.options.without_hidden() }
}

///|
/// Restricts results to files when querying a filesystem.
pub fn GlobQuery::files_only(self : GlobQuery) -> GlobQuery {
  { ..self, options: self.options.files_only() }
}

///|
/// Restricts results to directories when querying a filesystem.
pub fn GlobQuery::directories_only(self : GlobQuery) -> GlobQuery {
  { ..self, options: self.options.directories_only() }
}

///|
/// Returns the number of include rules.
pub fn GlobQuery::include_count(self : GlobQuery) -> Int {
  self.includes.length()
}

///|
/// Returns the number of exclude rules.
pub fn GlobQuery::exclude_count(self : GlobQuery) -> Int {
  self.excludes.length()
}

///|
fn query_matches_include(query : GlobQuery, path : String) -> Bool {
  if query.includes.is_empty() {
    return true
  }
  match_compiled_any(query.includes, path)
}

///|
fn query_matches_exclude(query : GlobQuery, path : String) -> Bool {
  match_compiled_any(query.excludes, path)
}

///|
fn query_within_depth(query : GlobQuery, path : String) -> Bool {
  let depth = path_depth(path)
  if depth < query.min_depth {
    return false
  }
  match query.options.max_depth {
    None => true
    Some(max_depth) => depth <= max_depth
  }
}

///|
fn query_accepts(query : GlobQuery, path : String) -> Bool {
  if !query.options.include_hidden && is_hidden_path(path) {
    return false
  }
  query_within_depth(query, path) && query_matches_include(query, path)
}

///|
/// Applies query type filters while retaining the metadata held by an index.
fn query_accepts_record(query : GlobQuery, entry : PathRecord) -> Bool {
  if entry.is_file() && !query.options.include_files {
    return false
  }
  if entry.is_directory() && !query.options.include_directories {
    return false
  }
  query_accepts(query, entry.path)
}

///|
/// Tests a normalized or platform-specific path against this query.
pub fn GlobQuery::matches(self : GlobQuery, path : String) -> Bool {
  let normalized = normalize_path(path)
  query_accepts(self, normalized) && !query_matches_exclude(self, normalized)
}

///|
/// Executes this query against a caller-provided path list.
pub fn GlobQuery::execute_paths(
  self : GlobQuery,
  paths : Array[String],
) -> QueryReport {
  let mut examined = 0
  let mut included = 0
  let mut excluded = 0
  let mut truncated = false
  let results : Array[String] = []
  let seen : Array[String] = []
  for path in paths {
    examined = examined + 1
    let normalized = normalize_path(path)
    if query_accepts(self, normalized) {
      if query_matches_exclude(self, normalized) {
        excluded = excluded + 1
      } else {
        included = included + 1
        if !seen.contains(normalized) {
          seen.push(normalized)
          match self.limit {
            Some(limit) if results.length() >= limit => truncated = true
            _ => results.push(normalized)
          }
        }
      }
    }
  }
  if self.options.sort_results {
    results.sort()
  }
  {
    examined,
    included,
    excluded,
    returned: results.length(),
    truncated,
    results,
  }
}

///|
/// Executes a query against an in-memory index without discarding entry kinds.
/// This is useful for build tools that refresh a path index once and issue many
/// queries without repeatedly touching the filesystem.
pub fn GlobQuery::execute_index(
  self : GlobQuery,
  index : PathIndex,
) -> QueryReport {
  let mut examined = 0
  let mut included = 0
  let mut excluded = 0
  let mut truncated = false
  let results : Array[String] = []
  let seen : Array[String] = []
  for entry in index.records() {
    examined = examined + 1
    if query_accepts_record(self, entry) {
      if query_matches_exclude(self, entry.path) {
        excluded = excluded + 1
      } else {
        included = included + 1
        if !seen.contains(entry.path) {
          seen.push(entry.path)
          match self.limit {
            Some(limit) if results.length() >= limit => truncated = true
            _ => results.push(entry.path)
          }
        }
      }
    }
  }
  if self.options.sort_results {
    results.sort()
  }
  {
    examined,
    included,
    excluded,
    returned: results.length(),
    truncated,
    results,
  }
}

///|
/// Executes the query against all traversable entries under a directory.
pub fn GlobQuery::execute_filesystem(
  self : GlobQuery,
  dir : String,
) -> Result[QueryReport, GlobError] {
  let traversal_pattern = if self.includes.is_empty() { "**/*" } else { "**/*" }
  match glob_with_options(dir, traversal_pattern, self.options) {
    Err(err) => Err(err)
    Ok(paths) => Ok(self.execute_paths(paths))
  }
}

///|
/// Returns a concise configuration summary for logs and diagnostics.
pub fn GlobQuery::summary(self : GlobQuery) -> String {
  let max_depth = match self.options.max_depth {
    None => "none"
    Some(depth) => depth.to_string()
  }
  let limit = match self.limit {
    None => "none"
    Some(value) => value.to_string()
  }
  "includes=" +
  self.include_count().to_string() +
  ",excludes=" +
  self.exclude_count().to_string() +
  ",min_depth=" +
  self.min_depth.to_string() +
  ",max_depth=" +
  max_depth +
  ",limit=" +
  limit +
  ",hidden=" +
  self.options.include_hidden.to_string() +
  ",sorted=" +
  self.options.sort_results.to_string()
}

///|
/// Creates a query from include and exclude source patterns.
pub fn build_query(
  includes : Array[String],
  excludes : Array[String],
) -> Result[GlobQuery, GlobError] {
  let mut query = GlobQuery::new()
  for pattern in includes {
    match query.include_pattern(pattern) {
      Ok(next) => query = next
      Err(err) => return Err(err)
    }
  }
  for pattern in excludes {
    match query.exclude_pattern(pattern) {
      Ok(next) => query = next
      Err(err) => return Err(err)
    }
  }
  Ok(query)
}

///|
/// Executes a one-shot include/exclude query over a path list.
pub fn query_paths(
  includes : Array[String],
  excludes : Array[String],
  paths : Array[String],
) -> Result[QueryReport, GlobError] {
  match build_query(includes, excludes) {
    Err(err) => Err(err)
    Ok(query) => Ok(query.execute_paths(paths))
  }
}

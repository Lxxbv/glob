// High-level cached filtering pipeline for build systems and index consumers.

///|
pub enum PipelineError {
  InvalidLimit
} derive(Debug, Eq)

///|
pub impl Show for PipelineError with fn output(self, logger) {
  match self {
    PipelineError::InvalidLimit => logger.write_string("InvalidLimit")
  }
}

///|
pub(all) struct PipelineReport {
  scanned : Int
  included : Int
  excluded : Int
  returned : Int
  truncated : Bool
  results : Array[String]
  cache_hits : Int
  cache_misses : Int
} derive(Debug, Eq)

///|
pub(all) struct GlobPipeline {
  cache : PatternCache
  includes : Array[String]
  excludes : Array[String]
  options : GlobOptions
  limit : Int?
} derive(Debug, Eq)

///|
/// Creates a pipeline with a bounded compiled-pattern cache.
pub fn GlobPipeline::new(
  cache_capacity : Int,
) -> Result[GlobPipeline, CacheError] {
  match PatternCache::new(cache_capacity) {
    Err(err) => Err(err)
    Ok(cache) =>
      Ok({
        cache,
        includes: [],
        excludes: [],
        options: GlobOptions::default(),
        limit: None,
      })
  }
}

///|
pub fn GlobPipeline::include_pattern(
  self : GlobPipeline,
  pattern : String,
) -> GlobPipeline {
  let includes = self.includes.copy()
  includes.push(pattern)
  { ..self, includes, }
}

///|
pub fn GlobPipeline::exclude_pattern(
  self : GlobPipeline,
  pattern : String,
) -> GlobPipeline {
  let excludes = self.excludes.copy()
  excludes.push(pattern)
  { ..self, excludes, }
}

///|
pub fn GlobPipeline::with_options(
  self : GlobPipeline,
  options : GlobOptions,
) -> GlobPipeline {
  { ..self, options, }
}

///|
pub fn GlobPipeline::sorted(self : GlobPipeline) -> GlobPipeline {
  { ..self, options: self.options.sorted() }
}

///|
pub fn GlobPipeline::without_hidden(self : GlobPipeline) -> GlobPipeline {
  { ..self, options: self.options.without_hidden() }
}

///|
pub fn GlobPipeline::with_limit(
  self : GlobPipeline,
  limit : Int,
) -> Result[GlobPipeline, PipelineError] {
  if limit < 0 {
    Err(PipelineError::InvalidLimit)
  } else {
    Ok({ ..self, limit: Some(limit) })
  }
}

///|
pub fn GlobPipeline::include_count(self : GlobPipeline) -> Int {
  self.includes.length()
}

///|
pub fn GlobPipeline::exclude_count(self : GlobPipeline) -> Int {
  self.excludes.length()
}

///|
fn within_options(path : String, options : GlobOptions) -> Bool {
  if !options.include_hidden && is_hidden_path(path) {
    return false
  }
  match options.max_depth {
    None => true
    Some(max_depth) => path_depth(path) <= max_depth
  }
}

///|
fn pipeline_matches(
  cache : PatternCache,
  patterns : Array[String],
  path : String,
) -> Result[(PatternCache, Bool), GlobError] {
  if patterns.is_empty() {
    Ok((cache, true))
  } else {
    cache.match_any(patterns, [path])
  }
}

///|
/// Runs include/exclude matching once over a candidate path array.
pub fn GlobPipeline::run_with_cache(
  self : GlobPipeline,
  paths : Array[String],
) -> Result[(GlobPipeline, PipelineReport), GlobError] {
  let mut cache = self.cache
  let results : Array[String] = []
  let mut included = 0
  let mut excluded = 0
  let mut truncated = false
  for raw_path in paths {
    let path = normalize_path(raw_path)
    if !within_options(path, self.options) {
      continue
    }
    match pipeline_matches(cache, self.includes, path) {
      Err(err) => return Err(err)
      Ok((include_cache, included_match)) => {
        cache = include_cache
        if !included_match {
          continue
        }
        match pipeline_matches(cache, self.excludes, path) {
          Err(err) => return Err(err)
          Ok((exclude_cache, excluded_match)) => {
            cache = exclude_cache
            if excluded_match && !self.excludes.is_empty() {
              excluded = excluded + 1
              continue
            }
            included = included + 1
            match self.limit {
              None => if !results.contains(path) { results.push(path) }
              Some(limit) =>
                if results.length() < limit {
                  if !results.contains(path) {
                    results.push(path)
                  }
                } else {
                  truncated = true
                }
            }
          }
        }
      }
    }
  }
  if self.options.sort_results {
    results.sort()
  }
  let stats = cache.stats()
  let report = {
    scanned: paths.length(),
    included,
    excluded,
    returned: results.length(),
    truncated,
    results,
    cache_hits: stats.hits,
    cache_misses: stats.misses,
  }
  Ok(({ ..self, cache, }, report))
}

///|
/// Runs a pipeline and returns only the report for one-shot callers.
pub fn GlobPipeline::run(
  self : GlobPipeline,
  paths : Array[String],
) -> Result[PipelineReport, GlobError] {
  match self.run_with_cache(paths) {
    Err(err) => Err(err)
    Ok((_, report)) => Ok(report)
  }
}

///|
pub fn PipelineReport::summary(self : PipelineReport) -> String {
  "scanned=" +
  self.scanned.to_string() +
  " included=" +
  self.included.to_string() +
  " excluded=" +
  self.excluded.to_string() +
  " returned=" +
  self.returned.to_string() +
  " truncated=" +
  self.truncated.to_string() +
  " cache_hits=" +
  self.cache_hits.to_string()
}

///|
pub fn PipelineReport::has_results(self : PipelineReport) -> Bool {
  !self.results.is_empty()
}

///|
pub fn PipelineReport::csv_header(_self : PipelineReport) -> String {
  "scanned,included,excluded,returned,truncated,cache_hits,cache_misses"
}

///|
pub fn PipelineReport::csv_row(self : PipelineReport) -> String {
  self.scanned.to_string() +
  "," +
  self.included.to_string() +
  "," +
  self.excluded.to_string() +
  "," +
  self.returned.to_string() +
  "," +
  self.truncated.to_string() +
  "," +
  self.cache_hits.to_string() +
  "," +
  self.cache_misses.to_string()
}

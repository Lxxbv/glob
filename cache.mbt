// Bounded compiled-pattern cache for repeated queries.
//
// The cache is explicit and value-based: every operation returns the updated
// cache together with its result.  That makes hit/miss behavior deterministic
// in tests and avoids hidden global state in library consumers.

///|
pub enum CacheError {
  InvalidCapacity
} derive(Debug, Eq)

///|
pub impl Show for CacheError with fn output(self, logger) {
  match self {
    CacheError::InvalidCapacity => logger.write_string("InvalidCapacity")
  }
}

///|
pub(all) struct CacheStats {
  entries : Int
  capacity : Int
  hits : Int
  misses : Int
  evictions : Int
} derive(Debug, Eq)

///|
pub(all) struct CachedPattern {
  source : String
  compiled : CompiledPattern
  hits : Int
} derive(Debug, Eq)

///|
pub(all) struct PatternCache {
  entries : Array[CachedPattern]
  capacity : Int
  hits : Int
  misses : Int
  evictions : Int
} derive(Debug, Eq)

///|
pub fn PatternCache::new(capacity : Int) -> Result[PatternCache, CacheError] {
  if capacity <= 0 {
    Err(CacheError::InvalidCapacity)
  } else {
    Ok({ entries: [], capacity, hits: 0, misses: 0, evictions: 0 })
  }
}

///|
fn PatternCache::find_index(self : PatternCache, source : String) -> Int? {
  let mut i = 0
  while i < self.entries.length() {
    if self.entries[i].source == source {
      return Some(i)
    }
    i = i + 1
  }
  None
}

///|
fn drop_oldest(entries : Array[CachedPattern]) -> Array[CachedPattern] {
  let result : Array[CachedPattern] = []
  let mut i = 1
  while i < entries.length() {
    result.push(entries[i])
    i = i + 1
  }
  result
}

///|
/// Returns a compiled pattern and an updated cache.
pub fn PatternCache::get_or_compile(
  self : PatternCache,
  source : String,
) -> Result[(PatternCache, CompiledPattern), GlobError] {
  match self.find_index(source) {
    Some(index) => {
      let entries = self.entries.copy()
      let current = entries[index]
      entries[index] = { ..current, hits: current.hits + 1 }
      let next = { ..self, entries, hits: self.hits + 1 }
      Ok((next, current.compiled))
    }
    None =>
      match compile_pattern(source) {
        Err(err) => Err(err)
        Ok(compiled) => {
          let mut entries = self.entries.copy()
          let mut evictions = self.evictions
          if entries.length() >= self.capacity {
            entries = drop_oldest(entries)
            evictions = evictions + 1
          }
          entries.push({ source, compiled, hits: 0 })
          let next = { ..self, entries, misses: self.misses + 1, evictions }
          Ok((next, compiled))
        }
      }
  }
}

///|
pub fn PatternCache::contains(self : PatternCache, source : String) -> Bool {
  self.find_index(source) is Some(_)
}

///|
pub fn PatternCache::entries_count(self : PatternCache) -> Int {
  self.entries.length()
}

///|
pub fn PatternCache::stats(self : PatternCache) -> CacheStats {
  {
    entries: self.entries.length(),
    capacity: self.capacity,
    hits: self.hits,
    misses: self.misses,
    evictions: self.evictions,
  }
}

///|
/// Clears cached entries and counters while retaining the configured bound.
pub fn PatternCache::clear(self : PatternCache) -> PatternCache {
  { ..self, entries: [], hits: 0, misses: 0, evictions: 0 }
}

///|
/// Compiles a batch and preserves the first parser error.
pub fn PatternCache::compile_all(
  self : PatternCache,
  sources : Array[String],
) -> Result[(PatternCache, Array[CompiledPattern]), GlobError] {
  let mut cache = self
  let result : Array[CompiledPattern] = []
  for source in sources {
    match cache.get_or_compile(source) {
      Err(err) => return Err(err)
      Ok((next, compiled)) => {
        cache = next
        result.push(compiled)
      }
    }
  }
  Ok((cache, result))
}

///|
/// Tests whether at least one cached/compiled pattern matches any path.
pub fn PatternCache::match_any(
  self : PatternCache,
  sources : Array[String],
  paths : Array[String],
) -> Result[(PatternCache, Bool), GlobError] {
  match self.compile_all(sources) {
    Err(err) => Err(err)
    Ok((cache, patterns)) => {
      let mut matched = false
      for pattern in patterns {
        for path in paths {
          if pattern.matches(path) {
            matched = true
          }
        }
      }
      Ok((cache, matched))
    }
  }
}

///|
/// Tests whether every pattern matches one path.
pub fn PatternCache::match_all(
  self : PatternCache,
  sources : Array[String],
  path : String,
) -> Result[(PatternCache, Bool), GlobError] {
  match self.compile_all(sources) {
    Err(err) => Err(err)
    Ok((cache, patterns)) => {
      let mut matched = true
      for pattern in patterns {
        if !pattern.matches(path) {
          matched = false
        }
      }
      Ok((cache, matched))
    }
  }
}

///|
/// Filters paths with a cached pattern.
pub fn PatternCache::filter(
  self : PatternCache,
  source : String,
  paths : Array[String],
) -> Result[(PatternCache, Array[String]), GlobError] {
  match self.get_or_compile(source) {
    Err(err) => Err(err)
    Ok((cache, compiled)) => {
      let result : Array[String] = []
      for path in paths {
        if compiled.matches(path) {
          result.push(path)
        }
      }
      Ok((cache, result))
    }
  }
}

///|
/// Returns all cached source names in oldest-to-newest order.
pub fn PatternCache::sources(self : PatternCache) -> Array[String] {
  let result : Array[String] = []
  for entry in self.entries {
    result.push(entry.source)
  }
  result
}

///|
pub fn PatternCache::capacity(self : PatternCache) -> Int {
  self.capacity
}

///|
pub fn PatternCache::hit_rate_percent(self : PatternCache) -> Int {
  let total = self.hits + self.misses
  if total == 0 {
    0
  } else {
    self.hits * 100 / total
  }
}

///|
pub fn PatternCache::summary(self : PatternCache) -> String {
  "cache entries=" +
  self.entries.length().to_string() +
  "/" +
  self.capacity.to_string() +
  " hits=" +
  self.hits.to_string() +
  " misses=" +
  self.misses.to_string() +
  " evictions=" +
  self.evictions.to_string()
}

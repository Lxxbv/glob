// In-memory indexing primitives for repeated glob queries.
//
// The index deliberately uses compact arrays instead of a hidden filesystem
// cache.  This keeps the API deterministic, makes it useful for build tools,
// and lets callers refresh a batch of paths without depending on OS watchers.

///|
/// The kind of filesystem entry represented by a path record.
pub enum PathKind {
  File
  Directory
} derive(Debug, Eq)

///|
/// A normalized path plus metadata used by filtering and reporting tools.
pub(all) struct PathRecord {
  path : String
  kind : PathKind
  depth : Int
  basename : String
  extension : String?
  hidden : Bool
} derive(Debug, Eq)

///|
/// Summary statistics for an in-memory path index.
pub(all) struct IndexStats {
  total : Int
  files : Int
  directories : Int
  hidden : Int
  max_depth : Int
} derive(Debug, Eq)

///|
/// An ordered, duplicate-free collection of normalized path records.
pub(all) struct PathIndex {
  entries : Array[PathRecord]
  generation : Int
} derive(Debug, Eq)

///|
fn trim_trailing_separator(path : String) -> String {
  let normalized = normalize_path(path)
  let mut end = normalized.length()
  while end > 0 && normalized[end - 1].to_int().unsafe_to_char() == '/' {
    end = end - 1
  }
  if end == 0 && !normalized.is_empty() {
    "/"
  } else {
    normalized[:end].to_owned()
  }
}

///|
fn make_record(path : String, kind : PathKind) -> PathRecord {
  let normalized = trim_trailing_separator(path)
  {
    path: normalized,
    kind,
    depth: path_depth(normalized),
    basename: basename(normalized),
    extension: extension(normalized),
    hidden: is_hidden_path(normalized),
  }
}

///|
/// Creates a file record.
pub fn PathRecord::file(path : String) -> PathRecord {
  make_record(path, PathKind::File)
}

///|
/// Creates a directory record.
pub fn PathRecord::directory(path : String) -> PathRecord {
  make_record(path, PathKind::Directory)
}

///|
/// Creates a record with an explicit kind.
pub fn PathRecord::new(path : String, kind : PathKind) -> PathRecord {
  make_record(path, kind)
}

///|
pub fn PathRecord::is_file(self : PathRecord) -> Bool {
  self.kind == PathKind::File
}

///|
pub fn PathRecord::is_directory(self : PathRecord) -> Bool {
  self.kind == PathKind::Directory
}

///|
/// Returns true when the record path matches a compiled glob.
pub fn PathRecord::matches(
  self : PathRecord,
  pattern : CompiledPattern,
) -> Bool {
  pattern.matches(self.path)
}

///|
/// Starts with an empty index.
pub fn PathIndex::new() -> PathIndex {
  { entries: [], generation: 0 }
}

///|
/// Builds an index while removing duplicate normalized paths.
pub fn PathIndex::from_entries(entries : Array[PathRecord]) -> PathIndex {
  let mut index = PathIndex::new()
  for entry in entries {
    index = index.add_record(entry)
  }
  index
}

///|
fn PathIndex::add_record(self : PathIndex, entry : PathRecord) -> PathIndex {
  let entries = self.entries.copy()
  let mut replaced = false
  let mut i = 0
  while i < entries.length() {
    if entries[i].path == entry.path {
      entries[i] = entry
      replaced = true
      break
    }
    i = i + 1
  }
  if !replaced {
    entries.push(entry)
  }
  { entries, generation: self.generation + 1 }
}

///|
/// Inserts or replaces a file record.
pub fn PathIndex::add_file(self : PathIndex, path : String) -> PathIndex {
  self.add_record(PathRecord::file(path))
}

///|
/// Inserts or replaces a directory record.
pub fn PathIndex::add_directory(self : PathIndex, path : String) -> PathIndex {
  self.add_record(PathRecord::directory(path))
}

///|
/// Inserts a batch of records in input order.
pub fn PathIndex::add_many(
  self : PathIndex,
  entries : Array[PathRecord],
) -> PathIndex {
  let mut result = self
  for entry in entries {
    result = result.add_record(entry)
  }
  result
}

///|
/// Returns the number of records.
pub fn PathIndex::length(self : PathIndex) -> Int {
  self.entries.length()
}

///|
pub fn PathIndex::is_empty(self : PathIndex) -> Bool {
  self.entries.is_empty()
}

///|
/// Returns the current mutation generation, useful for cache invalidation.
pub fn PathIndex::generation(self : PathIndex) -> Int {
  self.generation
}

///|
pub fn PathIndex::contains(self : PathIndex, path : String) -> Bool {
  let normalized = trim_trailing_separator(path)
  for entry in self.entries {
    if entry.path == normalized {
      return true
    }
  }
  false
}

///|
/// Returns the record for a normalized path, if indexed.
pub fn PathIndex::get(self : PathIndex, path : String) -> PathRecord? {
  let normalized = trim_trailing_separator(path)
  for entry in self.entries {
    if entry.path == normalized {
      return Some(entry)
    }
  }
  None
}

///|
/// Removes one path and returns the resulting index.
pub fn PathIndex::remove(self : PathIndex, path : String) -> PathIndex {
  let normalized = trim_trailing_separator(path)
  let entries : Array[PathRecord] = []
  for entry in self.entries {
    if entry.path != normalized {
      entries.push(entry)
    }
  }
  { entries, generation: self.generation + 1 }
}

///|
/// Removes all records while advancing the generation.
pub fn PathIndex::clear(self : PathIndex) -> PathIndex {
  { entries: [], generation: self.generation + 1 }
}

///|
/// Returns records in insertion order.
pub fn PathIndex::records(self : PathIndex) -> Array[PathRecord] {
  self.entries.copy()
}

///|
pub fn PathIndex::files(self : PathIndex) -> Array[PathRecord] {
  let result : Array[PathRecord] = []
  for entry in self.entries {
    if entry.is_file() {
      result.push(entry)
    }
  }
  result
}

///|
pub fn PathIndex::directories(self : PathIndex) -> Array[PathRecord] {
  let result : Array[PathRecord] = []
  for entry in self.entries {
    if entry.is_directory() {
      result.push(entry)
    }
  }
  result
}

///|
/// Returns records at or below a normalized directory prefix.
pub fn PathIndex::under(self : PathIndex, prefix : String) -> Array[PathRecord] {
  let normalized = trim_trailing_separator(prefix)
  let result : Array[PathRecord] = []
  for entry in self.entries {
    if normalized == "." ||
      normalized.is_empty() ||
      entry.path == normalized ||
      entry.path.has_prefix(normalized + "/") {
      result.push(entry)
    }
  }
  result
}

///|
/// Returns direct children of a directory, excluding deeper descendants.
pub fn PathIndex::children(
  self : PathIndex,
  parent : String,
) -> Array[PathRecord] {
  let normalized = trim_trailing_separator(parent)
  let result : Array[PathRecord] = []
  for entry in self.entries {
    if dirname(entry.path) == normalized {
      result.push(entry)
    }
  }
  result
}

///|
/// Matches all indexed records with one compiled pattern.
pub fn PathIndex::search_compiled(
  self : PathIndex,
  pattern : CompiledPattern,
) -> Array[PathRecord] {
  let result : Array[PathRecord] = []
  for entry in self.entries {
    if pattern.matches(entry.path) {
      result.push(entry)
    }
  }
  result
}

///|
/// Compiles and applies one pattern to the index.
pub fn PathIndex::query(
  self : PathIndex,
  pattern : String,
) -> Result[Array[PathRecord], GlobError] {
  match compile_pattern(pattern) {
    Err(err) => Err(err)
    Ok(compiled) => Ok(self.search_compiled(compiled))
  }
}

///|
/// Applies include/exclude rules to the indexed paths.
pub fn PathIndex::apply_rules(
  self : PathIndex,
  rules : GlobRules,
) -> Array[PathRecord] {
  let result : Array[PathRecord] = []
  for entry in self.entries {
    if rules.allows(entry.path, entry.is_directory()) {
      result.push(entry)
    }
  }
  result
}

///|
/// Computes stable aggregate statistics.
pub fn PathIndex::stats(self : PathIndex) -> IndexStats {
  let mut files = 0
  let mut directories = 0
  let mut hidden = 0
  let mut max_depth = 0
  for entry in self.entries {
    if entry.is_file() {
      files = files + 1
    } else {
      directories = directories + 1
    }
    if entry.hidden {
      hidden = hidden + 1
    }
    if entry.depth > max_depth {
      max_depth = entry.depth
    }
  }
  { total: self.entries.length(), files, directories, hidden, max_depth }
}

///|
/// Counts records with one extension, without treating directories specially.
pub fn PathIndex::count_extension(self : PathIndex, wanted : String) -> Int {
  let mut count = 0
  for entry in self.entries {
    match entry.extension {
      Some(value) => if value == wanted { count = count + 1 }
      None => ()
    }
  }
  count
}

///|
/// Returns records matching a pattern and optional rule set.
pub fn PathIndex::query_with_rules(
  self : PathIndex,
  pattern : String,
  rules : GlobRules,
) -> Result[Array[PathRecord], GlobError] {
  match self.query(pattern) {
    Err(err) => Err(err)
    Ok(records) => {
      let result : Array[PathRecord] = []
      for entry in records {
        if rules.allows(entry.path, entry.is_directory()) {
          result.push(entry)
        }
      }
      Ok(result)
    }
  }
}

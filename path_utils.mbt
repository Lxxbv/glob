// Portable path helpers used by filesystem search and public callers.

///|
/// Converts Windows separators to `/`, removes duplicate separators, and
/// removes a leading `./` from a relative path.
pub fn normalize_path(path : String) -> String {
  let builder = StringBuilder::new()
  let mut previous_separator = false
  let mut i = 0
  while i < path.length() {
    let c = path[i].to_int().unsafe_to_char()
    if c == '/' || c == '\\' {
      if !previous_separator {
        builder.write_char('/')
      }
      previous_separator = true
    } else {
      builder.write_char(c)
      previous_separator = false
    }
    i = i + 1
  }
  let result = builder.to_string()
  if result.has_prefix("./") {
    result[2:].to_owned()
  } else if result == "." {
    ""
  } else {
    result
  }
}

///|
/// Returns the number of non-empty path components.
pub fn path_depth(path : String) -> Int {
  let normalized = normalize_path(path)
  if normalized.is_empty() || normalized == "/" {
    0
  } else {
    let mut depth = 1
    let mut i = 0
    while i < normalized.length() {
      if normalized[i].to_int().unsafe_to_char() == '/' {
        depth = depth + 1
      }
      i = i + 1
    }
    depth
  }
}

///|
/// Returns the final component of a path.
pub fn basename(path : String) -> String {
  let normalized = normalize_path(path)
  let trimmed = if normalized.has_suffix("/") {
    normalized[:normalized.length() - 1].to_owned()
  } else {
    normalized
  }
  let mut last_separator = -1
  let mut i = 0
  while i < trimmed.length() {
    if trimmed[i].to_int().unsafe_to_char() == '/' {
      last_separator = i
    }
    i = i + 1
  }
  if last_separator < 0 {
    trimmed
  } else {
    trimmed[last_separator + 1:].to_owned()
  }
}

///|
/// Returns the parent path, or `.` when the path has no parent.
pub fn dirname(path : String) -> String {
  let normalized = normalize_path(path)
  let trimmed = if normalized.has_suffix("/") {
    normalized[:normalized.length() - 1].to_owned()
  } else {
    normalized
  }
  let mut last_separator = -1
  let mut i = 0
  while i < trimmed.length() {
    if trimmed[i].to_int().unsafe_to_char() == '/' {
      last_separator = i
    }
    i = i + 1
  }
  if last_separator < 0 {
    "."
  } else if last_separator == 0 {
    "/"
  } else {
    trimmed[:last_separator].to_owned()
  }
}

///|
/// Returns the final extension without the leading dot.
pub fn extension(path : String) -> String? {
  let name = basename(path)
  let mut last_dot = -1
  let mut i = 0
  while i < name.length() {
    if name[i].to_int().unsafe_to_char() == '.' {
      last_dot = i
    }
    i = i + 1
  }
  if last_dot <= 0 || last_dot + 1 >= name.length() {
    None
  } else {
    Some(name[last_dot + 1:].to_owned())
  }
}

///|
/// Returns true when any path component starts with a dot.
pub fn is_hidden_path(path : String) -> Bool {
  let normalized = normalize_path(path)
  let mut component_start = 0
  let mut i = 0
  while i <= normalized.length() {
    if i == normalized.length() ||
      normalized[i].to_int().unsafe_to_char() == '/' {
      if i > component_start &&
        normalized[component_start].to_int().unsafe_to_char() == '.' {
        return true
      }
      component_start = i + 1
    }
    i = i + 1
  }
  false
}

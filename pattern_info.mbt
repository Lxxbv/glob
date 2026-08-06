// Lightweight metadata queries for glob patterns.

///|
fn count_separators(tokens : Array[Token]) -> Int {
  let mut count = 0
  for token in tokens {
    match token {
      Token::Text(text) => {
        let mut i = 0
        while i < text.length() {
          if text[i].to_int().unsafe_to_char() == '/' {
            count = count + 1
          }
          i = i + 1
        }
      }
      _ => ()
    }
  }
  count
}

///|
/// Returns the static prefix before the first wildcard construct.
pub fn literal_prefix(pattern : String) -> Result[String, GlobError] {
  let tokens = tokenize(pattern)
  match tokens {
    Err(err) => Err(err)
    Ok(tokens) =>
      // Compile too, so metadata APIs enforce the same complete syntax rules.
      match parse(tokens) {
        Err(err) => Err(err)
        Ok(_) => {
          let builder = StringBuilder::new()
          let mut stopped = false
          for token in tokens {
            if stopped {
              continue
            }
            match token {
              Token::Text(text) => builder.write_string(text)
              _ => stopped = true
            }
          }
          Ok(builder.to_string())
        }
      }
  }
}

///|
/// Returns the number of `/` separators in a valid pattern.
pub fn separator_count(pattern : String) -> Result[Int, GlobError] {
  match tokenize(pattern) {
    Err(err) => Err(err)
    Ok(tokens) =>
      match parse(tokens) {
        Err(err) => Err(err)
        Ok(_) => Ok(count_separators(tokens))
      }
  }
}

///|
/// Returns whether a pattern contains a recursive `**` wildcard.
pub fn has_recursive_wildcard(pattern : String) -> Result[Bool, GlobError] {
  match tokenize(pattern) {
    Err(err) => Err(err)
    Ok(tokens) =>
      match parse(tokens) {
        Err(err) => Err(err)
        Ok(_) => {
          let mut found = false
          for token in tokens {
            if token is Token::GlobStar {
              found = true
            }
          }
          Ok(found)
        }
      }
  }
}

///|
/// Returns whether a valid pattern contains a path separator.
pub fn is_path_pattern(pattern : String) -> Result[Bool, GlobError] {
  separator_count(pattern).map(fn(count) { count > 0 })
}

///|
fn append_segment(
  segments : Array[String],
  start : Int,
  end : Int,
  path : String,
) -> Unit {
  if end > start {
    segments.push(path[start:end].to_owned())
  }
}

///|
fn split_segments(path : String) -> Array[String] {
  let segments : Array[String] = []
  let mut start = 0
  let mut i = 0
  while i <= path.length() {
    if i == path.length() || path[i].to_int().unsafe_to_char() == '/' {
      append_segment(segments, start, i, path)
      start = i + 1
    }
    i = i + 1
  }
  segments
}

///|
/// Returns the literal path components known before the first wildcard.
pub fn static_segments(pattern : String) -> Result[Array[String], GlobError] {
  let prefix = literal_prefix(pattern)
  match prefix {
    Err(err) => Err(err)
    Ok(prefix) =>
      if prefix.is_empty() && !pattern.is_empty() {
        Err(GlobError::NonLiteralSegment)
      } else {
        Ok(split_segments(normalize_path(prefix)))
      }
  }
}

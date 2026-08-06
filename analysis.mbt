// Structural analysis of compiled glob patterns.

///|
/// Counts the syntax features in a compiled glob pattern.
pub(all) struct PatternStats {
  literal_chars : Int
  star_count : Int
  globstar_count : Int
  question_count : Int
  char_class_count : Int
  brace_group_count : Int
  escaped_char_count : Int
} derive(Debug, Eq)

///|
fn PatternStats::zero() -> PatternStats {
  {
    literal_chars: 0,
    star_count: 0,
    globstar_count: 0,
    question_count: 0,
    char_class_count: 0,
    brace_group_count: 0,
    escaped_char_count: 0,
  }
}

///|
fn add_stats(left : PatternStats, right : PatternStats) -> PatternStats {
  {
    literal_chars: left.literal_chars + right.literal_chars,
    star_count: left.star_count + right.star_count,
    globstar_count: left.globstar_count + right.globstar_count,
    question_count: left.question_count + right.question_count,
    char_class_count: left.char_class_count + right.char_class_count,
    brace_group_count: left.brace_group_count + right.brace_group_count,
    escaped_char_count: left.escaped_char_count + right.escaped_char_count,
  }
}

///|
fn ast_stats(ast : AST) -> PatternStats {
  match ast {
    AST::Text(text) => { ..PatternStats::zero(), literal_chars: text.length() }
    AST::Star => { ..PatternStats::zero(), star_count: 1 }
    AST::GlobStar => { ..PatternStats::zero(), globstar_count: 1 }
    AST::Question => { ..PatternStats::zero(), question_count: 1 }
    AST::CharClass(_, _) => { ..PatternStats::zero(), char_class_count: 1 }
    AST::Seq(nodes) => {
      let mut result = PatternStats::zero()
      for node in nodes {
        result = add_stats(result, ast_stats(node))
      }
      result
    }
    AST::Brace(options) => {
      let mut result = { ..PatternStats::zero(), brace_group_count: 1 }
      for option in options {
        for node in option {
          result = add_stats(result, ast_stats(node))
        }
      }
      result
    }
  }
}

///|
fn count_escaped_chars(pattern : String) -> Int {
  let mut count = 0
  let mut i = 0
  while i + 1 < pattern.length() {
    if pattern[i].to_int().unsafe_to_char() == '\\' {
      count = count + 1
      i = i + 2
    } else {
      i = i + 1
    }
  }
  count
}

///|
/// Compiles and analyzes a pattern without performing any path matching.
pub fn analyze(pattern : String) -> Result[PatternStats, GlobError] {
  match compile(pattern) {
    Ok(ast) => {
      let stats = ast_stats(ast)
      Ok({ ..stats, escaped_char_count: count_escaped_chars(pattern) })
    }
    Err(err) => Err(err)
  }
}

///|
/// Returns the number of syntax constructs that require matching logic.
pub fn PatternStats::magic_count(self : PatternStats) -> Int {
  self.star_count +
  self.globstar_count +
  self.question_count +
  self.char_class_count +
  self.brace_group_count
}

///|
/// Returns true when the pattern contains no wildcard constructs.
pub fn PatternStats::is_literal(self : PatternStats) -> Bool {
  self.magic_count() == 0
}

///|
/// Returns true when the pattern has at least one wildcard construct.
pub fn PatternStats::has_magic(self : PatternStats) -> Bool {
  !self.is_literal()
}

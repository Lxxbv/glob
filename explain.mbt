// Human-readable diagnostics for glob patterns.
//
// These APIs are intentionally independent from the matcher.  They are useful
// in command-line tools, benchmark reports, and bug tickets where showing the
// parsed structure is more actionable than returning only true or false.

///|
/// A coarse risk category used to choose traversal and caching strategies.
pub enum PatternRisk {
  Literal
  Bounded
  Recursive
  HighBranching
} derive(Debug, Eq)

///|
/// A complete, stable explanation of one validated pattern.
pub(all) struct PatternExplanation {
  source : String
  normalized : String
  tokens : Array[String]
  ast_text : String
  stats : PatternStats
  risk : PatternRisk
  literal_prefix : String
  separator_count : Int
} derive(Debug, Eq)

///|
fn char_label(c : Char) -> String {
  "'" + c.to_string() + "'"
}

///|
fn token_label(token : Token) -> String {
  match token {
    Token::Text(text) => "Text(\"" + text + "\")"
    Token::Question => "Question"
    Token::Star => "Star"
    Token::GlobStar => "GlobStar"
    Token::LBrace => "LBrace"
    Token::RBrace => "RBrace"
    Token::Comma => "Comma"
    Token::LBracket => "LBracket"
    Token::RBracket => "RBracket"
    Token::Negate => "Negate"
    Token::Char(c) => "Char(" + char_label(c) + ")"
    Token::Range(start, end) =>
      "Range(" + char_label(start) + "," + char_label(end) + ")"
  }
}

///|
fn render_tokens(tokens : Array[Token]) -> Array[String] {
  let result : Array[String] = []
  for token in tokens {
    result.push(token_label(token))
  }
  result
}

///|
fn render_elements(elements : Array[CharClassElement]) -> String {
  let builder = StringBuilder::new()
  builder.write_char('[')
  for element in elements {
    match element {
      CharClassElement::Single(c) => builder.write_string(char_label(c))
      CharClassElement::Range(start, end) => {
        builder.write_string(char_label(start))
        builder.write_char('-')
        builder.write_string(char_label(end))
      }
    }
  }
  builder.write_char(']')
  builder.to_string()
}

///|
fn render_ast_into(ast : AST, builder : StringBuilder) -> Unit {
  match ast {
    AST::Text(text) => builder.write_string("Text(\"" + text + "\")")
    AST::Question => builder.write_string("Question")
    AST::Star => builder.write_string("Star")
    AST::GlobStar => builder.write_string("GlobStar")
    AST::CharClass(negated, elements) => {
      builder.write_string("CharClass(")
      if negated {
        builder.write_string("negated,")
      } else {
        builder.write_string("positive,")
      }
      builder.write_string(render_elements(elements))
      builder.write_char(')')
    }
    AST::Brace(options) => {
      builder.write_string("Brace(")
      let mut first_option = true
      for option in options {
        if !first_option {
          builder.write_char('|')
        }
        first_option = false
        builder.write_char('[')
        let mut first_node = true
        for node in option {
          if !first_node {
            builder.write_char(',')
          }
          first_node = false
          render_ast_into(node, builder)
        }
        builder.write_char(']')
      }
      builder.write_char(')')
    }
    AST::Seq(nodes) => {
      builder.write_string("Seq(")
      let mut first = true
      for node in nodes {
        if !first {
          builder.write_char(',')
        }
        first = false
        render_ast_into(node, builder)
      }
      builder.write_char(')')
    }
  }
}

///|
fn render_ast(ast : AST) -> String {
  let builder = StringBuilder::new()
  render_ast_into(ast, builder)
  builder.to_string()
}

///|
fn classify_risk(stats : PatternStats) -> PatternRisk {
  if stats.is_literal() {
    PatternRisk::Literal
  } else if stats.brace_group_count >= 3 ||
    stats.char_class_count >= 4 ||
    stats.star_count >= 5 {
    PatternRisk::HighBranching
  } else if stats.globstar_count > 0 {
    PatternRisk::Recursive
  } else {
    PatternRisk::Bounded
  }
}

///|
/// Parses a pattern and returns all information needed for diagnostics.
pub fn explain_pattern(
  pattern : String,
) -> Result[PatternExplanation, GlobError] {
  match tokenize(pattern) {
    Err(err) => Err(err)
    Ok(tokens) =>
      match parse(tokens) {
        Err(err) => Err(err)
        Ok(ast) => {
          let stats = {
            ..ast_stats(ast),
            escaped_char_count: count_escaped_chars(pattern),
          }
          let prefix = literal_prefix(pattern).unwrap()
          let separators = separator_count(pattern).unwrap()
          Ok({
            source: pattern,
            normalized: normalize_path(pattern),
            tokens: render_tokens(tokens),
            ast_text: render_ast(ast),
            stats,
            risk: classify_risk(stats),
            literal_prefix: prefix,
            separator_count: separators,
          })
        }
      }
  }
}

///|
pub fn PatternExplanation::is_literal(self : PatternExplanation) -> Bool {
  self.risk == PatternRisk::Literal
}

///|
pub fn PatternExplanation::complexity_score(self : PatternExplanation) -> Int {
  self.stats.magic_count() * 10 + self.stats.escaped_char_count
}

///|
/// Returns a compact machine-readable category name.
pub fn PatternExplanation::risk_name(self : PatternExplanation) -> String {
  match self.risk {
    PatternRisk::Literal => "literal"
    PatternRisk::Bounded => "bounded"
    PatternRisk::Recursive => "recursive"
    PatternRisk::HighBranching => "high-branching"
  }
}

///|
/// Recommends a caller-visible execution strategy.
pub fn PatternExplanation::recommendation(self : PatternExplanation) -> String {
  match self.risk {
    PatternRisk::Literal => "use an exact path lookup"
    PatternRisk::Bounded => "compile once and filter candidate paths"
    PatternRisk::Recursive =>
      "use the literal prefix to prune traversal before matching"
    PatternRisk::HighBranching =>
      "bound candidate breadth and report a match limit to the caller"
  }
}

///|
/// Produces a stable identifier suitable for benchmark grouping.
pub fn PatternExplanation::signature(self : PatternExplanation) -> String {
  "glob:v1:" +
  self.risk_name() +
  ":" +
  self.complexity_score().to_string() +
  ":" +
  self.literal_prefix
}

///|
pub fn PatternExplanation::token_count(self : PatternExplanation) -> Int {
  self.tokens.length()
}

///|
pub fn PatternExplanation::has_recursive_wildcard(
  self : PatternExplanation,
) -> Bool {
  self.stats.globstar_count > 0
}

///|
pub fn PatternExplanation::branch_count(self : PatternExplanation) -> Int {
  let mut branches = 1
  if self.stats.brace_group_count > 0 {
    branches = branches * (self.stats.brace_group_count + 1)
  }
  if self.stats.char_class_count > 0 {
    branches = branches * (self.stats.char_class_count + 1)
  }
  branches
}

///|
/// Renders a short one-line diagnostic for logs and CLI output.
pub fn PatternExplanation::summary(self : PatternExplanation) -> String {
  "pattern=\"" +
  self.source +
  "\" risk=" +
  self.risk_name() +
  " complexity=" +
  self.complexity_score().to_string() +
  " prefix=\"" +
  self.literal_prefix +
  "\" tokens=" +
  self.token_count().to_string()
}

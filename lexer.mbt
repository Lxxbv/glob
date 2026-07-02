// Lexical analyzer for Glob patterns.

///|
/// Tokenizes a glob pattern string into a sequence of Tokens.
pub fn tokenize(pattern : String) -> Result[Array[Token], GlobError] {
  let tokens : Array[Token] = []
  let len = pattern.length()
  let mut i = 0
  let mut in_brackets = false
  let current_text = StringBuilder::new()

  fn flush_text() {
    let s = current_text.to_string()
    if s.length() > 0 {
      tokens.push(Token::Text(s))
      current_text.reset()
    }
  }

  while i < len {
    let c = pattern[i].to_int().unsafe_to_char()
    if in_brackets {
      if c == ']' {
        flush_text()
        tokens.push(Token::RBracket)
        in_brackets = false
        i = i + 1
      } else if c == '!' || c == '^' {
        let last_token_is_lbracket = if tokens.length() > 0 {
          match tokens[tokens.length() - 1] {
            Token::LBracket => true
            _ => false
          }
        } else {
          false
        }
        if last_token_is_lbracket {
          tokens.push(Token::Negate)
        } else {
          tokens.push(Token::Char(c))
        }
        i = i + 1
        // Check for range, e.g. 'a-z'
      } else if i + 2 < len &&
        pattern[i + 1].to_int().unsafe_to_char() == '-' &&
        pattern[i + 2].to_int().unsafe_to_char() != ']' {
        let start = c
        let end = pattern[i + 2].to_int().unsafe_to_char()
        tokens.push(Token::Range(start, end))
        i = i + 3
      } else {
        tokens.push(Token::Char(c))
        i = i + 1
      }
    } else {
      match c {
        '\\' =>
          if i + 1 < len {
            current_text.write_char(pattern[i + 1].to_int().unsafe_to_char())
            i = i + 2
          } else {
            current_text.write_char('\\')
            i = i + 1
          }
        '*' => {
          flush_text()
          if i + 1 < len && pattern[i + 1].to_int().unsafe_to_char() == '*' {
            tokens.push(Token::GlobStar)
            i = i + 2
          } else {
            tokens.push(Token::Star)
            i = i + 1
          }
        }
        '?' => {
          flush_text()
          tokens.push(Token::Question)
          i = i + 1
        }
        '{' => {
          flush_text()
          tokens.push(Token::LBrace)
          i = i + 1
        }
        '}' => {
          flush_text()
          tokens.push(Token::RBrace)
          i = i + 1
        }
        ',' => {
          flush_text()
          tokens.push(Token::Comma)
          i = i + 1
        }
        '[' => {
          flush_text()
          tokens.push(Token::LBracket)
          in_brackets = true
          i = i + 1
        }
        _ => {
          current_text.write_char(c)
          i = i + 1
        }
      }
    }
  }
  flush_text()
  Ok(tokens)
}

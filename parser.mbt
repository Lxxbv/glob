// AST Parser for Glob patterns.

priv struct Parser {
  tokens : Array[Token]
  mut index : Int
}

/// Converts a flat array of Tokens into a hierarchical AST.
pub fn parse(tokens : Array[Token]) -> Result[AST, GlobError] {
  if tokens.length() == 0 {
    return Err(GlobError::EmptyPattern)
  }
  let parser = Parser::{ tokens, index: 0 }
  parser.parse_seq()
}

fn Parser::parse_seq(self : Parser) -> Result[AST, GlobError] {
  let nodes : Array[AST] = []
  while self.index < self.tokens.length() {
    let tok = self.tokens[self.index]
    match tok {
      Token::RBrace => break
      Token::Comma => break
      Token::RBracket => break
      Token::Text(s) => {
        nodes.push(AST::Text(s))
        self.index = self.index + 1
      }
      Token::Question => {
        nodes.push(AST::Question)
        self.index = self.index + 1
      }
      Token::Star => {
        nodes.push(AST::Star)
        self.index = self.index + 1
      }
      Token::GlobStar => {
        nodes.push(AST::GlobStar)
        self.index = self.index + 1
      }
      Token::LBrace => {
        match self.parse_brace() {
          Ok(brace_ast) => nodes.push(brace_ast)
          Err(err) => return Err(err)
        }
      }
      Token::LBracket => {
        match self.parse_bracket() {
          Ok(bracket_ast) => nodes.push(bracket_ast)
          Err(err) => return Err(err)
        }
      }
      _ => {
        nodes.push(AST::Text(token_to_string(tok)))
        self.index = self.index + 1
      }
    }
  }
  if nodes.length() == 1 {
    Ok(nodes[0])
  } else {
    Ok(AST::Seq(nodes))
  }
}

fn Parser::parse_brace(self : Parser) -> Result[AST, GlobError] {
  self.index = self.index + 1 // Consume LBrace
  let options : Array[Array[AST]] = []
  while self.index < self.tokens.length() {
    match self.parse_seq() {
      Ok(opt) => {
        if self.index < self.tokens.length() {
          let tok = self.tokens[self.index]
          if tok == Token::Comma {
            options.push(ast_to_array(opt))
            self.index = self.index + 1
          } else if tok == Token::RBrace {
            options.push(ast_to_array(opt))
            self.index = self.index + 1
            return Ok(AST::Brace(options))
          } else {
            return Err(GlobError::UnclosedBrace)
          }
        } else {
          return Err(GlobError::UnclosedBrace)
        }
      }
      Err(err) => return Err(err)
    }
  }
  Err(GlobError::UnclosedBrace)
}

fn Parser::parse_bracket(self : Parser) -> Result[AST, GlobError] {
  self.index = self.index + 1 // Consume LBracket
  if self.index >= self.tokens.length() {
    return Err(GlobError::UnclosedBracket)
  }

  let negate = if self.tokens[self.index] == Token::Negate {
    self.index = self.index + 1
    true
  } else {
    false
  }

  let elements : Array[CharClassElement] = []
  while self.index < self.tokens.length() {
    let tok = self.tokens[self.index]
    match tok {
      Token::RBracket => {
        self.index = self.index + 1
        return Ok(AST::CharClass(negate, elements))
      }
      Token::Char(c) => {
        elements.push(CharClassElement::Single(c))
        self.index = self.index + 1
      }
      Token::Range(start, end) => {
        elements.push(CharClassElement::Range(start, end))
        self.index = self.index + 1
      }
      _ => {
        let s = token_to_string(tok)
        let mut j = 0
        while j < s.length() {
          elements.push(CharClassElement::Single(s[j].to_int().unsafe_to_char()))
          j = j + 1
        }
        self.index = self.index + 1
      }
    }
  }
  Err(GlobError::UnclosedBracket)
}

fn ast_to_array(ast : AST) -> Array[AST] {
  match ast {
    AST::Seq(arr) => arr
    _ => [ast]
  }
}

fn token_to_string(tok : Token) -> String {
  match tok {
    Token::Text(s) => s
    Token::Question => "?"
    Token::Star => "*"
    Token::GlobStar => "**"
    Token::LBrace => "{"
    Token::RBrace => "}"
    Token::Comma => ","
    Token::LBracket => "["
    Token::RBracket => "]"
    Token::Negate => "!"
    Token::Char(c) => c.to_string()
    Token::Range(start, end) => start.to_string() + "-" + end.to_string()
  }
}

// Token and AST definitions for the Glob pattern matcher.

/// Represents a token produced by the Glob lexer.
pub enum Token {
  Text(String)
  Question        // '?'
  Star            // '*'
  GlobStar        // '**'
  LBrace          // '{'
  RBrace          // '}'
  Comma           // ','
  LBracket        // '['
  RBracket        // ']'
  Negate          // '!' or '^' (only right after '[')
  Char(Char)      // A single character inside brackets or as part of a range
  Range(Char, Char) // 'a-z' range
} derive(Show, Eq)

/// Represents a component inside a character class `[...]`.
pub enum CharClassElement {
  Single(Char)
  Range(Char, Char)
} derive(Show, Eq)

/// Represents the Abstract Syntax Tree (AST) of a Glob pattern.
pub enum AST {
  Text(String)
  Question
  Star
  GlobStar
  CharClass(Bool, Array[CharClassElement]) // (is_negated, elements)
  Brace(Array[Array[AST]])                 // {a,b,c}
  Seq(Array[AST])                          // Sequence of AST nodes
} derive(Show, Eq)

/// Represents errors that can occur during glob parsing.
pub enum GlobError {
  UnclosedBrace
  UnclosedBracket
  InvalidRange
  EmptyPattern
} derive(Show, Eq)

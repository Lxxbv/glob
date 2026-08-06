// Token and AST definitions for the Glob pattern matcher.

///|
/// Represents a token produced by the Glob lexer.
pub enum Token {
  Text(String)
  Question // '?'
  Star // '*'
  GlobStar // '**'
  LBrace // '{'
  RBrace // '}'
  Comma // ','
  LBracket // '['
  RBracket // ']'
  Negate // '!' or '^' (only right after '[')
  Char(Char) // A single character inside brackets or as part of a range
  Range(Char, Char) // 'a-z' range
} derive(Debug, Eq)

///|
/// Represents a component inside a character class `[...]`.
pub enum CharClassElement {
  Single(Char)
  Range(Char, Char)
} derive(Debug, Eq)

///|
/// Represents the Abstract Syntax Tree (AST) of a Glob pattern.
pub enum AST {
  Text(String)
  Question
  Star
  GlobStar
  CharClass(Bool, Array[CharClassElement]) // (is_negated, elements)
  Brace(Array[Array[AST]]) // {a,b,c}
  Seq(Array[AST]) // Sequence of AST nodes
} derive(Debug, Eq)

///|
/// Represents errors that can occur during glob parsing.
pub enum GlobError {
  UnclosedBrace
  UnclosedBracket
  InvalidRange
  EmptyPattern
  UnexpectedComma
  UnexpectedClosingBrace
  UnexpectedToken(String)
  InvalidMaxDepth
  NonLiteralSegment
  FilesystemError(String)
} derive(Debug, Eq)

///|
pub impl Show for GlobError with fn output(self, logger) {
  match self {
    GlobError::UnclosedBrace => logger.write_string("UnclosedBrace")
    GlobError::UnclosedBracket => logger.write_string("UnclosedBracket")
    GlobError::InvalidRange => logger.write_string("InvalidRange")
    GlobError::EmptyPattern => logger.write_string("EmptyPattern")
    GlobError::UnexpectedComma => logger.write_string("UnexpectedComma")
    GlobError::UnexpectedClosingBrace =>
      logger.write_string("UnexpectedClosingBrace")
    GlobError::UnexpectedToken(token) =>
      logger.write_string("UnexpectedToken(" + token + ")")
    GlobError::InvalidMaxDepth => logger.write_string("InvalidMaxDepth")
    GlobError::NonLiteralSegment => logger.write_string("NonLiteralSegment")
    GlobError::FilesystemError(message) =>
      logger.write_string("FilesystemError(" + message + ")")
  }
}

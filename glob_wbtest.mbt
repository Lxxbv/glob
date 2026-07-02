// Whitebox tests for the Glob Lexer.

test "tokenize basic text" {
  let tokens = tokenize("hello").unwrap()
  inspect!(tokens, content="[Text(hello)]")
}

test "tokenize wildcards" {
  let tokens = tokenize("?***").unwrap()
  inspect!(tokens, content="[Question, GlobStar, Star]")
}

test "tokenize escape characters" {
  let tokens = tokenize("a\\?b\\*c\\\\").unwrap()
  inspect!(tokens, content="[Text(a?b*c\\)]")
}

test "tokenize character classes" {
  let tokens = tokenize("[a-z]").unwrap()
  inspect!(tokens, content="[LBracket, Range(a, z), RBracket]")

  let tokens_neg = tokenize("[!0-9]").unwrap()
  inspect!(tokens_neg, content="[LBracket, Negate, Range(0, 9), RBracket]")
}

test "tokenize braces" {
  let tokens = tokenize("{a,b,c}").unwrap()
  inspect!(tokens, content="[LBrace, Text(a), Comma, Text(b), Comma, Text(c), RBrace]")
}

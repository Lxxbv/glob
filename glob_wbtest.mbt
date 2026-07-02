// Whitebox tests for the Glob Lexer and Parser.

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

test "parse basic text and wildcards" {
  let tokens = tokenize("a*b?c**").unwrap()
  let ast = parse(tokens).unwrap()
  inspect!(ast, content="Seq([Text(a), Star, Text(b), Question, Text(c), GlobStar])")
}

test "parse character classes" {
  let tokens = tokenize("[a-z]").unwrap()
  let ast = parse(tokens).unwrap()
  inspect!(ast, content="CharClass(false, [Range(a, z)])")

  let tokens_neg = tokenize("[!0-9a]").unwrap()
  let ast_neg = parse(tokens_neg).unwrap()
  inspect!(ast_neg, content="CharClass(true, [Range(0, 9), Single(a)])")
}

test "parse braces" {
  let tokens = tokenize("src/*.{mbt,json}").unwrap()
  let ast = parse(tokens).unwrap()
  inspect!(ast, content="Seq([Text(src/), Star, Text(.), Brace([[Text(mbt)], [Text(json)]])])")
}

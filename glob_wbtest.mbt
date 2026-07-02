// Whitebox tests for the Glob Lexer, Parser, and Matcher.

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

test "match basic text" {
  let ast = parse(tokenize("hello").unwrap()).unwrap()
  inspect!(match_path(ast, "hello"), content="true")
  inspect!(match_path(ast, "world"), content="false")
}

test "match star and question wildcards" {
  let ast1 = parse(tokenize("src/*.mbt").unwrap()).unwrap()
  inspect!(match_path(ast1, "src/main.mbt"), content="true")
  inspect!(match_path(ast1, "src/core/utils.mbt"), content="false") // Star doesn't match '/'
  inspect!(match_path(ast1, "src/main.json"), content="false")

  let ast2 = parse(tokenize("a?c").unwrap()).unwrap()
  inspect!(match_path(ast2, "abc"), content="true")
  inspect!(match_path(ast2, "abbc"), content="false")
}

test "match globstar" {
  let ast = parse(tokenize("src/**/*.mbt").unwrap()).unwrap()
  inspect!(match_path(ast, "src/main.mbt"), content="true")
  inspect!(match_path(ast, "src/core/utils.mbt"), content="true")
  inspect!(match_path(ast, "src/deep/nested/file.mbt"), content="true")
  inspect!(match_path(ast, "src/core/utils.json"), content="false")
}

test "match character classes" {
  let ast = parse(tokenize("file[0-9].txt").unwrap()).unwrap()
  inspect!(match_path(ast, "file5.txt"), content="true")
  inspect!(match_path(ast, "filea.txt"), content="false")

  let ast_neg = parse(tokenize("file[!0-9].txt").unwrap()).unwrap()
  inspect!(match_path(ast_neg, "filea.txt"), content="true")
  inspect!(match_path(ast_neg, "file5.txt"), content="false")
}

test "match braces" {
  let ast = parse(tokenize("src/*.{mbt,json}").unwrap()).unwrap()
  inspect!(match_path(ast, "src/main.mbt"), content="true")
  inspect!(match_path(ast, "src/config.json"), content="true")
  inspect!(match_path(ast, "src/main.rs"), content="false")
}

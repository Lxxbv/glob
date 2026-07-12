///|
test "bench compile" (b : @bench.T) {
  b.bench(fn() { b.keep(@glob.compile("src/**/*.mbt")) })
}

///|
test "bench match_path" (b : @bench.T) {
  match @glob.compile("src/**/*.mbt") {
    Ok(ast) =>
      b.bench(fn() { b.keep(@glob.match_path(ast, "src/core/parser.mbt")) })
    Err(_) => ()
  }
}

///|
test "bench glob search" (b : @bench.T) {
  b.bench(fn() { b.keep(@glob.glob(".", "cmd/**/*.mbt")) })
}

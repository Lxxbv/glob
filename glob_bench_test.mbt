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

///|
test "bench deterministic default workload evaluation" (b : @bench.T) {
  let workload = @glob.build_default_workload()
  b.bench(fn() { b.keep(@glob.evaluate_workload(workload)) })
}

///|
test "bench large workload through compiled pipeline" (b : @bench.T) {
  let workload = @glob.build_large_workload()
  let pipeline = @glob.GlobPipeline::new(32)
    .unwrap()
    .include_pattern("**/*.mbt")
    .exclude_pattern("**/*_test.mbt")
  b.bench(fn() { b.keep(pipeline.run(workload.paths())) })
}

///|
test "bench repeated cached filtering" (b : @bench.T) {
  let paths = @glob.build_default_workload().paths()
  let cache = @glob.PatternCache::new(16).unwrap()
  b.bench(fn() { b.keep(cache.filter("src/**/*.mbt", paths)) })
}

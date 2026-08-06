///|

///|
fn is_moon_run_program(arg : String) -> Bool {
  arg == "cmd/main" ||
  arg.has_suffix("cmd/main/main.js") ||
  arg.has_suffix("\\cmd\\main\\main.js")
}

///|
fn cli_query(args : Array[String]) -> (String, String)? {
  let moon_run_offset = if args.length() >= 2 && is_moon_run_program(args[1]) {
    1
  } else {
    0
  }
  let pattern_index = 1 + moon_run_offset
  if args.length() <= pattern_index {
    None
  } else {
    let dir_index = pattern_index + 1
    let dir = if args.length() > dir_index { args[dir_index] } else { "." }
    Some((args[pattern_index], dir))
  }
}

///|
fn main {
  let args = @env.args()
  match cli_query(args) {
    None => println("Usage: moon run cmd/main <pattern> [directory]")
    Some((pattern, dir)) =>
      match @glob.glob(dir, pattern) {
        Ok(paths) =>
          if paths.is_empty() {
            println("No matching files found.")
          } else {
            paths.sort()
            for path in paths {
              println(path)
            }
          }
        Err(err) => println("Error: \{err}")
      }
  }
}

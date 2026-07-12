///|
fn main {
  let args = @env.args()
  if args.length() < 2 {
    println("Usage: moon run cmd/main <pattern> [directory]")
    return
  }
  let pattern = args[1]
  let dir = if args.length() >= 3 { args[2] } else { "." }
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

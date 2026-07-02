fn main {
  let args = @env.args()
  if args.length() < 3 {
    println("Usage: moon run cmd/main <pattern> <path>")
    return
  }
  let pattern = args[1]
  let path = args[2]
  match @glob.match_pattern(pattern, path) {
    Ok(is_match) => {
      if is_match {
        println("Match!")
      } else {
        println("No match.")
      }
    }
    Err(err) => println("Error: \{err}")
  }
}

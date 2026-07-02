// Matcher implementation for Glob patterns.

/// Matches a path string against a parsed Glob AST.
pub fn match_path(ast : AST, path : String) -> Bool {
  let nodes = match ast {
    AST::Seq(arr) => arr
    _ => [ast]
  }
  match_state(nodes, 0, path, 0)
}

fn match_state(nodes : Array[AST], node_idx : Int, path : String, path_idx : Int) -> Bool {
  if node_idx == nodes.length() {
    return path_idx == path.length()
  }

  let node = nodes[node_idx]
  match node {
    AST::Text(s) => {
      let s_len = s.length()
      if path_idx + s_len <= path.length() {
        let mut match_ok = true
        let mut i = 0
        while i < s_len {
          let pc = path[path_idx + i].to_int().unsafe_to_char()
          let sc = s[i].to_int().unsafe_to_char()
          if pc != sc {
            match_ok = false
            break
          }
          i = i + 1
        }
        if match_ok {
          return match_state(nodes, node_idx + 1, path, path_idx + s_len)
        }
      }
      false
    }
    AST::Question => {
      if path_idx < path.length() {
        let c = path[path_idx].to_int().unsafe_to_char()
        if c != '/' {
          return match_state(nodes, node_idx + 1, path, path_idx + 1)
        }
      }
      false
    }
    AST::Star => {
      let mut k = 0
      let max_k = path.length() - path_idx
      while k <= max_k {
        if k > 0 {
          let prev_c = path[path_idx + k - 1].to_int().unsafe_to_char()
          if prev_c == '/' {
            break
          }
        }
        if match_state(nodes, node_idx + 1, path, path_idx + k) {
          return true
        }
        k = k + 1
      }
      false
    }
    AST::GlobStar => {
      let mut k = 0
      let max_k = path.length() - path_idx
      while k <= max_k {
        if match_state(nodes, node_idx + 1, path, path_idx + k) {
          return true
        }
        k = k + 1
      }
      false
    }
    AST::CharClass(negate, elements) => {
      if path_idx >= path.length() {
        return false
      }
      let c = path[path_idx].to_int().unsafe_to_char()
      if c == '/' {
        return false
      }
      let mut found = false
      let mut i = 0
      while i < elements.length() {
        match elements[i] {
          CharClassElement::Single(sc) => {
            if c == sc {
              found = true
              break
            }
          }
          CharClassElement::Range(start, end) => {
            if c >= start && c <= end {
              found = true
              break
            }
          }
        }
        i = i + 1
      }
      if found == !negate {
        return match_state(nodes, node_idx + 1, path, path_idx + 1)
      }
      false
    }
    AST::Brace(options) => {
      let mut i = 0
      while i < options.length() {
        let opt = options[i]
        let new_nodes : Array[AST] = []
        let mut j = 0
        while j < opt.length() {
          new_nodes.push(opt[j])
          j = j + 1
        }
        let mut j = node_idx + 1
        while j < nodes.length() {
          new_nodes.push(nodes[j])
          j = j + 1
        }
        if match_state(new_nodes, 0, path, path_idx) {
          return true
        }
        i = i + 1
      }
      false
    }
    AST::Seq(_) => false
  }
}

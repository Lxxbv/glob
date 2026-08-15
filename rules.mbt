// Ignore/allow rule evaluation for source trees, build outputs, and caches.

///|
/// The action encoded by one ignore-file rule.
pub enum RuleAction {
  Include
  Exclude
} derive(Debug, Eq)

///|
/// The result of evaluating all rules for one path.
pub enum RuleDecision {
  Included
  Excluded
  Unmatched
} derive(Debug, Eq)

///|
/// One parsed rule with the original source retained for diagnostics.
pub(all) struct GlobRule {
  source : String
  pattern : CompiledPattern
  action : RuleAction
  anchored : Bool
  directory_only : Bool
  has_separator : Bool
} derive(Debug, Eq)

///|
/// An ordered rule set using last-match-wins evaluation.
pub(all) struct GlobRules {
  rules : Array[GlobRule]
} derive(Debug, Eq)

///|
fn trim_rule_line(line : String) -> String {
  line.trim().to_owned()
}

///|
fn strip_rule_suffix(value : String, suffix : String) -> (String, Bool) {
  if value.has_suffix(suffix) {
    (value[:value.length() - suffix.length()].to_owned(), true)
  } else {
    (value, false)
  }
}

///|
fn parse_rule_line(line : String) -> Result[GlobRule?, GlobError] {
  let trimmed = trim_rule_line(line)
  if trimmed.is_empty() || trimmed.has_prefix("#") {
    return Ok(None)
  }
  let mut action = RuleAction::Exclude
  let mut body = trimmed
  if body.has_prefix("!") {
    action = RuleAction::Include
    body = body[1:].to_owned()
  }
  let (without_suffix, directory_only) = strip_rule_suffix(body, "/")
  body = without_suffix
  let anchored = body.has_prefix("/")
  if anchored {
    body = body[1:].to_owned()
  }
  if body.is_empty() {
    return Err(GlobError::EmptyPattern)
  }
  let has_separator = match separator_count(body) {
    Ok(count) => count > 0
    Err(_) => false
  }
  match compile_pattern(body) {
    Err(err) => Err(err)
    Ok(pattern) =>
      Ok(
        Some({
          source: trimmed,
          pattern,
          action,
          anchored,
          directory_only,
          has_separator,
        }),
      )
  }
}

///|
/// Parses lines using common .gitignore-style comments and blank lines.
pub fn GlobRules::from_lines(
  lines : Array[String],
) -> Result[GlobRules, GlobError] {
  let rules : Array[GlobRule] = []
  for line in lines {
    match parse_rule_line(line) {
      Err(err) => return Err(err)
      Ok(None) => ()
      Ok(Some(rule)) => rules.push(rule)
    }
  }
  Ok({ rules, })
}

///|
/// Parses a newline-separated rule document.
pub fn GlobRules::from_text(text : String) -> Result[GlobRules, GlobError] {
  let lines : Array[String] = []
  let mut start = 0
  let mut i = 0
  while i <= text.length() {
    if i == text.length() || text[i].to_int().unsafe_to_char() == '\n' {
      let mut line = text[start:i].to_owned()
      if line.has_suffix("\r") {
        line = line[:line.length() - 1].to_owned()
      }
      lines.push(line)
      start = i + 1
    }
    i = i + 1
  }
  GlobRules::from_lines(lines)
}

///|
pub fn GlobRules::rule_count(self : GlobRules) -> Int {
  self.rules.length()
}

///|
pub fn GlobRules::is_empty(self : GlobRules) -> Bool {
  self.rules.is_empty()
}

///|
fn rule_matches(rule : GlobRule, path : String, _is_directory : Bool) -> Bool {
  let normalized = normalize_path(path)
  if rule.directory_only {
    let directory_name = normalize_path(rule.pattern.literal_prefix())
    if normalized != directory_name &&
      !normalized.has_prefix(directory_name + "/") {
      return false
    }
    if rule.anchored && !normalized.has_prefix(directory_name) {
      return false
    }
    return true
  }
  if rule.has_separator || rule.anchored {
    return rule.pattern.matches(normalized)
  }
  rule.pattern.matches(basename(normalized))
}

///|
/// Evaluates a path with last-match-wins semantics.
pub fn GlobRules::decision(
  self : GlobRules,
  path : String,
  is_directory : Bool,
) -> RuleDecision {
  let mut decision = RuleDecision::Unmatched
  for rule in self.rules {
    if rule_matches(rule, path, is_directory) {
      decision = match rule.action {
        RuleAction::Include => RuleDecision::Included
        RuleAction::Exclude => RuleDecision::Excluded
      }
    }
  }
  decision
}

///|
/// Returns whether a path should remain visible after rule evaluation.
pub fn GlobRules::allows(
  self : GlobRules,
  path : String,
  is_directory : Bool,
) -> Bool {
  match self.decision(path, is_directory) {
    RuleDecision::Excluded => false
    RuleDecision::Included => true
    RuleDecision::Unmatched => true
  }
}

///|
/// Filters a path list, treating every entry as a file.
pub fn GlobRules::filter(
  self : GlobRules,
  paths : Array[String],
) -> Array[String] {
  let result : Array[String] = []
  for path in paths {
    if self.allows(path, false) {
      let normalized = normalize_path(path)
      if !result.contains(normalized) {
        result.push(normalized)
      }
    }
  }
  result
}

///|
/// Filters paths when the caller knows which entries are directories.
pub fn GlobRules::filter_with_kinds(
  self : GlobRules,
  entries : Array[(String, Bool)],
) -> Array[String] {
  let result : Array[String] = []
  for entry in entries {
    let (path, is_directory) = entry
    if self.allows(path, is_directory) {
      let normalized = normalize_path(path)
      if !result.contains(normalized) {
        result.push(normalized)
      }
    }
  }
  result
}

///|
/// Describes the last rule that affects a path.
pub fn GlobRules::explain(
  self : GlobRules,
  path : String,
  is_directory : Bool,
) -> String {
  let normalized = normalize_path(path)
  let mut matched_source : String? = None
  let mut decision = RuleDecision::Unmatched
  for rule in self.rules {
    if rule_matches(rule, normalized, is_directory) {
      matched_source = Some(rule.source)
      decision = match rule.action {
        RuleAction::Include => RuleDecision::Included
        RuleAction::Exclude => RuleDecision::Excluded
      }
    }
  }
  let decision_text = match decision {
    RuleDecision::Included => "Included"
    RuleDecision::Excluded => "Excluded"
    RuleDecision::Unmatched => "Unmatched"
  }
  match matched_source {
    None => normalized + ":" + decision_text
    Some(source) => normalized + ":" + decision_text + " by " + source
  }
}

///|
/// Returns all rules in their source order for tooling integrations.
pub fn GlobRules::to_array(self : GlobRules) -> Array[GlobRule] {
  self.rules
}

///|
/// Appends another rule set while preserving evaluation order.
pub fn GlobRules::append(self : GlobRules, other : GlobRules) -> GlobRules {
  let rules = self.rules.copy()
  for rule in other.rules {
    rules.push(rule)
  }
  { rules, }
}

///|
/// Returns the count of include rules in this set.
pub fn GlobRules::include_count(self : GlobRules) -> Int {
  let mut count = 0
  for rule in self.rules {
    if rule.action == RuleAction::Include {
      count = count + 1
    }
  }
  count
}

///|
/// Returns the count of exclude rules in this set.
pub fn GlobRules::exclude_count(self : GlobRules) -> Int {
  self.rule_count() - self.include_count()
}

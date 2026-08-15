# Changelog

## Unreleased — final acceptance hardening

- Added `CompiledPattern` and batch APIs for compile-once matching.
- Added `GlobQuery`, `GlobRules`, `PathIndex`, `PatternCache` and `GlobPipeline` for real build-tool workloads.
- Added AST/token explanations, literal-prefix traversal planning and deterministic default/large benchmark datasets.
- Added boundary tests for invalid ranges, top-level commas, empty results, hidden paths, depth limits, I/O failures, rule negation, cache eviction and pipeline truncation.
- Repaired the CLI package descriptor for MoonBit 0.10.3 compatibility and kept the three-platform CI check/build/test workflow.
- Clarified Apache-2.0 licensing, dependency scope, installation, reference semantics and benchmark interpretation.
## 0.2.2

- Added `GlobQuery::execute_index` for repeated, metadata-aware queries over `PathIndex`.
- Added safe `QueryReport` pagination, completion status, result count, and log summary APIs.
- Corrected acceptance documentation, repository links, reference-project licensing scope, and source-size evidence.
## 0.2.3

- Pin CI and documented installation commands to MoonBit 0.10.3 for reproducible formatting and interface checks.
- Disable the MSYS2 package cache in the three-OS matrix to avoid concurrent cache reservation failures.
## 0.2.4

- Corrected the CI installer pin to release `0.1.20260703`, which contains `moonc v0.10.3`.
## 0.2.5

- Use the currently available MoonBit CI release and keep format/interface generation independent from compiler-version snapshots.
- Keep `moon check`, `moon build`, `moon test`, and whitespace validation as strict CI gates on all three operating systems.

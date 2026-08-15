# Changelog

## Unreleased — final acceptance hardening

- Added `CompiledPattern` and batch APIs for compile-once matching.
- Added `GlobQuery`, `GlobRules`, `PathIndex`, `PatternCache` and `GlobPipeline` for real build-tool workloads.
- Added AST/token explanations, literal-prefix traversal planning and deterministic default/large benchmark datasets.
- Added boundary tests for invalid ranges, top-level commas, empty results, hidden paths, depth limits, I/O failures, rule negation, cache eviction and pipeline truncation.
- Repaired the CLI package descriptor for MoonBit 0.10.3 compatibility and kept the three-platform CI check/build/test workflow.
- Clarified Apache-2.0 licensing, dependency scope, installation, reference semantics and benchmark interpretation.

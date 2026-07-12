// Learn more about moon.mod configuration:
// https://docs.moonbitlang.com/en/latest/toolchain/moon/module.html
//
// To add a dependency, run this command in your terminal:
//   moon add moonbitlang/x
//
// Or manually declare it in `import`, for example:
// import {
//   "moonbitlang/x@0.4.6",
// }

name = "Lxxbv/glob"

version = "0.1.2"

readme = "README.mbt.md"

repository = "https://github.com/Lxxbv/glob"

license = "Apache-2.0"

keywords = [ "glob", "pattern-matching", "wildcard", "filepath", "path" ]

description = "高性能、零依赖的通配符路径匹配与检索库，专为 MoonBit 语言设计并针对 Wasm / Native 双端进行了深度优化。"

import {
  "moonbitlang/x@0.4.46",
}

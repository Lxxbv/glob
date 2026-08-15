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

version = "0.2.4"

readme = "README.mbt.md"

repository = "https://github.com/Lxxbv/glob"

license = "Apache-2.0"

keywords = [ "glob", "pattern-matching", "wildcard", "filepath", "path" ]

description = "面向 MoonBit 的可复用通配符路径匹配与文件检索库，支持 Wasm、JS 与 Native 目标。"

import {
  "moonbitlang/x@0.4.46",
}

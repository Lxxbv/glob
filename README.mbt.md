# glob-mbt: 高性能文件路径通配符匹配与检索库

`glob-mbt` 是一个专门为 MoonBit 语言设计的高性能、零依赖路径通配符（Glob）匹配与文件检索库。类似于 Go 语言的 `path/filepath.Match` 和 JavaScript 生态的 `picomatch`/`minimatch`。

本项目针对 WebAssembly (Wasm) 与 Native 目标进行了双重优化，适用于构建工具、静态网站生成器、CLI 文件检索工具以及后台服务等场景。

## 特性

* **完整语法支持**：支持 `*`、`?`、`**`（多级目录）、`[char-class]`（字符集/范围）以及 `{group1,group2}`（花括号展开）。
* **高性能编译器架构**：采用词法分析（Lexer）与语法分析（Parser）构建抽象语法树（AST），并通过回溯匹配引擎进行剪枝优化，避免无效路径回溯。
* **零外部依赖**：仅依赖 MoonBit 标准库，具有极佳的可移植性。
* **命令行工具 (CLI)**：内置 `moon-glob` 实用工具，可直接在终端中进行通配符路径检索。

## 支持的通配符语法

| 语法 | 说明 | 示例 |
| :--- | :--- | :--- |
| `*` | 匹配单层目录下的任意数量字符（不包括路径分隔符 `/`） | `src/*.mbt` 匹配 `src/main.mbt`，但不匹配 `src/core/utils.mbt` |
| `?` | 匹配任意单个非路径分隔符字符 | `test_?.mbt` 匹配 `test_a.mbt` |
| `**` | 跨目录匹配任意层级的目录 and 文件（且支持匹配 0 个目录，即 `**/` 可为空） | `src/**/*.mbt` 匹配 `src/main.mbt` 和 `src/core/utils.mbt` |
| `[abc]` | 匹配括号内的任意单个字符 | `file[0-9].txt` 匹配 `file5.txt` |
| `[!abc]` | 匹配不在括号内的任意单个字符 | `file[!0-9].txt` 匹配 `filea.txt` |
| `{a,b,c}` | 花括号展开，匹配逗号分隔的任意一个模式 | `src/*.{mbt,json}` 匹配 `src/a.mbt` 和 `src/b.json` |
| `\` | 转义字符，用于匹配通配符本身 | `file\*` 匹配名为 `file*` 的文件 |

## 安装与配置

在你的 MoonBit 项目的 `moon.mod` 中声明对该模块的依赖。如果是本地模块，可以直接在 `moon.pkg` 中导入：

```moonbit nocheck
import {
  "caassien/glob"
}
```

## 使用方法

### 1. 作为库使用

#### 基础模式匹配
```moonbit nocheck
///|
fn example() {
  // 一次性匹配（适合低频调用）
  match @glob.match_pattern("src/**/*.mbt", "src/core/parser.mbt") {
    Ok(is_match) => println("Is match: \{is_match}") // 输出: Is match: true
    Err(err) => println("Error: \{err}")
  }
}
```

#### 编译模式匹配（推荐用于高频/循环匹配）
```moonbit nocheck
///|
fn example_compiled() {
  // 编译模式为 AST，避免重复解析的开销
  match @glob.compile("src/**/*.mbt") {
    Ok(ast) => {
      let files = ["src/main.mbt", "src/core/utils.mbt", "src/main.json"]
      for file in files {
        if @glob.match_path(ast, file) {
          println("Matched: \{file}")
        }
      }
    }
    Err(err) => println("Failed to compile: \{err}")
  }
}
```

### 2. 作为命令行工具使用

你可以直接使用 `moon run` 运行内置的 CLI 工具：

```bash
# 格式：moon run cmd/main <pattern> <path>
moon run cmd/main "src/**/*.mbt" "src/lexer.mbt"
# 输出: Match!

moon run cmd/main "src/**/*.mbt" "src/lexer.json"
# 输出: No match.
```

## 运行测试

使用 MoonBit 内置的测试工具运行所有单元测试与规格测试：

```bash
moon test
```

## 许可证

本项目采用 [Apache-2.0 License](LICENSE) 许可证。
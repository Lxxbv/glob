# Lxxbv/glob

`Lxxbv/glob` 是一个面向 MoonBit 的跨平台 Glob 路径匹配与文件检索库。它把模式解析为 AST，再进行可复用匹配；同时提供文件系统遍历、批量查询、忽略规则、内存路径索引、解释诊断、编译缓存和确定性基准工作负载。

项目定位是构建工具、静态站点生成器、CLI 文件检索器和后台扫描任务的基础库。它不是对任意 Shell 语法的完整模拟，也不会执行用户输入的命令。

## 当前能力

- 词法分析、语法分析和 AST：支持 `*`、`?`、`**`、字符类、范围、否定字符类、花括号展开和反斜杠转义。
- 可复用编译：`CompiledPattern` 保存 AST、复杂度统计、字面量前缀和递归通配符信息，适合循环匹配。
- 文件系统搜索：`glob` / `glob_with_options` 支持文件、目录、隐藏项、最大深度和排序；I/O 失败通过 `GlobError::FilesystemError` 返回。
- 组合查询：`GlobQuery` 和 `GlobPipeline` 支持 include/exclude、深度、隐藏项、排序、去重、限制返回数量和截断报告。
- 索引查询：`GlobQuery::execute_index` 支持在已构建的 `PathIndex` 上重复查询，并保留文件/目录类型过滤；`QueryReport` 提供分页、摘要和截断状态。
- 忽略规则：`GlobRules` 使用类似 `.gitignore` 的注释、否定规则、锚定规则、目录规则和 last-match-wins 语义。
- 路径索引：`PathIndex` 保存规范化路径、文件/目录类型、深度、扩展名和隐藏属性，支持前缀、子项、模式和规则查询。
- 诊断与性能：`explain_pattern` 输出 token、AST、复杂度和风险分类；`PatternCache` 统计命中、未命中和淘汰；`GlobWorkload` 提供 284/1404 条候选路径规模的可重复基准数据。

“高性能”在本项目中有明确边界：减少重复解析、利用静态目录前缀缩小初始遍历、复用编译缓存；实际速度取决于目标平台、文件系统和工作负载，必须以 `moon bench` 的本机结果为准。

## Glob 语义

| 语法 | 语义 | 示例 |
| --- | --- | --- |
| `*` | 匹配单个路径组件内的零个或多个字符，不跨 `/` | `src/*.mbt` |
| `?` | 匹配单个非 `/` 字符 | `test_?.mbt` |
| `**` | 递归匹配目录层级，可匹配零层目录 | `src/**/*.mbt` |
| `[abc]` | 匹配字符类中的一个字符 | `file[abc].txt` |
| `[a-z]` | 匹配字符范围中的一个字符 | `file[0-9].txt` |
| `[!abc]` / `[^abc]` | 匹配不在字符类中的一个字符 | `file[!0-9].txt` |
| `{a,b}` | 展开为多个候选分支 | `*.{mbt,json}` |
| `\` | 转义下一个字符，使通配符按普通字符处理 | `file\*.txt` |

顶层逗号不是独立的 Glob 通配符；只有花括号内部的逗号才表示分支。未闭合花括号、未闭合字符类、反向范围、空模式和文件系统 I/O 失败都会返回 `GlobError`，不会静默吞错。

实现参考了 Go 的 [`path/filepath.Match`](https://pkg.go.dev/path/filepath#Match) 和 JavaScript 生态的 [`minimatch`](https://github.com/isaacs/minimatch)，但本项目的 AST、错误类型、`**` 递归边界和文件系统 API 是独立实现，不能把不同项目的边界行为直接等同。

### 参考项目与许可证范围

本项目是独立的 MoonBit 实现，未复制 [`justjavac/glob`](https://github.com/justjavac/glob)、Go 标准库或 `minimatch` 的源代码；上述项目仅用于比较 Glob 语义和 API 设计。若下游继续复用这些项目的代码或测试数据，应分别遵守其仓库中声明的许可证和版权要求。本仓库自身的实现、测试和文档按根目录 [Apache License 2.0](LICENSE) 发布，MoonBit 依赖通过 `moon.mod` 显式声明。

## 安装与运行

### 安装 MoonBit 工具链

组委会验收环境使用 MoonBit 0.10.3。建议先安装并检查版本：

```powershell
# Windows PowerShell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
$env:MOONBIT_INSTALL_VERSION = "0.1.20260807"  # current CI release; local acceptance also passes on moonc v0.10.3
irm https://cli.moonbitlang.com/install/powershell.ps1 | iex
moon version --all
```

Linux/macOS：

```bash
MOONBIT_INSTALL_VERSION=0.1.20260807 bash -c "\$(curl -fsSL https://cli.moonbitlang.com/install/unix.sh)"  # current CI release; local acceptance uses moonc v0.10.3
echo "$HOME/.moon/bin" >> "$GITHUB_PATH"  # CI 环境；本地请按 Shell 配置 PATH
moon version --all
```

### 作为依赖使用

在消费者模块目录运行：

```bash
moon add Lxxbv/glob
moon install
```

如果需要使用仓库中的 CLI 包，构建系统支持将可执行包作为 binary 依赖：

```bash
moon add Lxxbv/glob --bin
moon install
```

依赖版本以消费者的 `moon.mod` 和锁定/缓存状态为准；本仓库不在源码中隐藏额外运行时依赖。

### 直接运行仓库 CLI

```bash
moon run cmd/main "**/*.mbt"
moon run cmd/main "src/**/*.mbt" "src"
```

CLI 输出相对于指定目录的匹配路径；没有匹配项时输出提示，模式解析或 I/O 失败时输出错误信息。

## API 示例

一次性匹配：

```moonbit nocheck
match @glob.match_pattern("src/**/*.mbt", "src/core/parser.mbt") {
  Ok(true) => println("matched")
  Ok(false) => println("not matched")
  Err(err) => println("pattern error: \{err}")
}
```

高频循环应编译一次：

```moonbit nocheck
let compiled = @glob.compile_pattern("src/**/*.mbt")?
let candidates = ["src/main.mbt", "src/core/parser.mbt", "docs/readme.md"]
let result = @glob.filter_compiled_patterns([compiled], candidates)
```

带文件系统选项的检索：

```moonbit nocheck
let options = @glob.GlobOptions::default()
  .files_only()
  .without_hidden()
  .sorted()
  .with_max_depth(4)?
let files = @glob.glob_with_options(".", "**/*.mbt", options)?
```

组合 include/exclude 查询：

```moonbit nocheck
let query = @glob.GlobQuery::new()
  .include_pattern("src/**/*.mbt")?
  .exclude_pattern("**/generated/**")?
  .without_hidden()
  .sorted()
let report = query.execute_paths(["src/main.mbt", "src/generated/api.mbt"])

// 对已经建立的索引重复查询，避免每次重新访问文件系统。
let indexed_report = query.execute_index(index)
let first_page = indexed_report.page(0, 20)
```

规则、索引和诊断：

```moonbit nocheck
let rules = @glob.GlobRules::from_text("*.tmp\n!important.tmp\n")?
let index = @glob.PathIndex::from_entries([
  @glob.PathRecord::file("src/main.mbt"),
  @glob.PathRecord::directory("src"),
])
let matched = index.query_with_rules("src/**/*.mbt", rules)?
let explanation = @glob.explain_pattern("src/{lib,test}/**/*.mbt")?
println(explanation.summary())
```

重复模式查询可以显式携带缓存，读取命中率：

```moonbit nocheck
let cache = @glob.PatternCache::new(32)?
let (cache, files) = cache.filter("src/**/*.mbt", candidates)?
println(cache.summary())
```

## 测试、边界和基准

本地验收建议在仓库根目录执行：

```bash
moon fmt
moon clean
moon info
moon check --deny-warn --target all
moon build --target all
moon test --deny-warn --target all
moon bench
git diff --check
```

当前测试覆盖解析错误、逗号/花括号、字符范围、转义、Windows 分隔符、隐藏路径、最大深度、空匹配、I/O 错误、规则否定、索引去重、缓存淘汰、工作负载统计和限制截断。确定性工作负载可直接运行：

```moonbit nocheck
let workload = @glob.build_default_workload()
let result = @glob.evaluate_workload(workload)
println(result.summary())
```

`build_default_workload()` 包含源代码、测试、文档、JSON、生成文件、隐藏缓存和嵌套资源，默认约 284 条候选路径；`build_large_workload()` 约 1404 条候选路径，适合比较编译复用、缓存和遍历策略。基准输出不写入仓库，也不宣称跨机器固定的纳秒数。

## 工程结构

- `lexer.mbt` / `parser.mbt` / `types.mbt`：词法、语法和 AST。
- `matcher.mbt` / `glob.mbt`：匹配器与文件系统搜索。
- `compiled.mbt` / `cache.mbt` / `traversal.mbt`：编译复用、缓存和静态前缀剪枝。
- `query.mbt` / `pipeline.mbt` / `rules.mbt`：组合查询、批处理和忽略规则。
- `index.mbt` / `explain.mbt` / `workload.mbt`：路径索引、诊断和可重复工作负载。
- `cmd/main`：可直接运行的 CLI。
- `.github/workflows/check.yml`：Linux、macOS、Windows 的 check/build/test/fmt/info CI，Windows native 使用 MSYS2 UCRT64 GCC。

项目当前以 20 个生产 `.mbt` 文件、3396 行生产实现和 73 个自动化测试为本地验收基线；测试代码与生成的 `.mbti` 接口文件不计入生产代码规模。有效非空非注释实现约 2928 行，后续扩展只增加真实功能，不以注释或重复代码填充规模。

## 开源合规

本项目使用 [Apache License 2.0](LICENSE)。版权和许可声明保留在仓库根目录；依赖通过 `moon.mod` 显式声明，不复制第三方源码。提交前请检查新增文件是否带有兼容许可证、是否误提交构建产物、个人密钥或本机路径。

## 项目仓库

- GitHub：<https://github.com/Lxxbv/glob>
- GitLink：<https://gitlink.org.cn/Lxxbv/glob>

## 贡献与版本

问题反馈请附上 MoonBit 版本、目标后端、操作系统、最小模式、候选路径以及可复现的 `moon test` 输出。版本号遵循 SemVer；破坏性 API 变化应记录在 [CHANGELOG.md](CHANGELOG.md)。

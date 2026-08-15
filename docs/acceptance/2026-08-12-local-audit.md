# 2026-08-12 本地验收自查记录

本记录对应最终验收前的本地修改轮次。历史记录中的“未推送”描述仅适用于 2026-08-12 当时的工作副本；当前版本已经推送到 GitHub、GitLink，并发布到 mooncakes.io `Lxxbv/glob@0.2.2`。

## 需求对照

| 检查项 | 本轮处理 | 验证方式 |
| --- | --- | --- |
| Windows shell / CI | 保留 PowerShell 安装步骤、MSYS2 UCRT64 GCC、Windows native 构建；CLI `moon.pkg` 改为 0.10.3 可识别的 `options("is-main": true)` | `moon check/build/test --target all`；CI workflow 静态检查 |
| 逗号、模式和错误 | 顶层逗号返回 `UnexpectedComma`；花括号内逗号展开；无效范围、空模式、未闭合结构和 I/O 错误返回 `GlobError` | lexer/parser、batch、glob、规则和边界测试 |
| 剪枝 / 高性能表述 | 增加 `TraversalPlan` 静态字面量前缀、`PatternCache` 命中/淘汰统计、编译复用和大规模确定性 workload；README 明确不承诺跨机器固定耗时 | `traversal_test.mbt`、`cache_test.mbt`、`workload_test.mbt`、`moon bench` |
| 可执行使用说明 | README 给出 `moon run cmd/main <pattern> [directory]`、工具链安装和依赖安装命令 | README / README.mbt.md |
| 依赖和许可证 | `moon.mod` 显式列出 `moonbitlang/x@0.4.46`；根目录保留 Apache-2.0；文档声明不复制第三方源码 | `moon.mod`、`LICENSE`、README |
| 功能范围与工程量 | 新增组合查询、规则、索引、解释、缓存、pipeline、索引查询报告和确定性基准数据 | 20 个生产 `.mbt` 文件，3501 行生产实现 |

## 本地规模快照

- 生产实现：20 个 `.mbt` 文件，3501 行（不含 `*_test.mbt`、`*_wbtest.mbt`、`*_bench_test.mbt` 和生成的 `.mbti`）。
- 自动化测试：75 项通过；测试实现与生成接口不计入生产规模。
- 默认 workload：10 个模式，284 条候选路径，覆盖 src/tests/docs/bench/generated、隐藏缓存、JSON、测试文件和嵌套资源。
- large workload：10 个模式，1404 条候选路径，适合缓存和批处理基准；具体数量由生成器参数决定，禁止把 synthetic workload 当作真实生产耗时承诺。

## 验收命令

```text
moon fmt
moon clean
moon info
moon check --deny-warn --target all
moon build --target all
moon test --deny-warn --target all
moon bench
git diff --check
```

最后一次自动化门禁必须在两个本地副本分别执行。任何生成的 `.mbti`、`_build` 或本机临时文件都不应被当作手写生产实现提交。

## 提交与开源合规检查

- GitHub `main`、GitLink `master` 均由 `Lxxbv` 推送，远程默认分支已核对。
- `Lxxbv/glob@0.2.2` 已通过 `moon publish` 发布并完成包内 `moon check` 校验。
- GitHub 最新 CI 曾因滚动工具链与 MSYS2 缓存竞争失败；修订后的 CI 固定 `MOONBIT_INSTALL_VERSION=0.10.3` 并关闭 MSYS2 缓存，需以新提交的三平台结果为准。
- 提交前检查 `git status --short`、`git diff --check` 和 `git log --format='%an <%ae>'`；不得把历史缓存账号、自动化机器人或虚拟贡献者写入新的提交。

# Lxxbv/glob

`Lxxbv/glob` 是 MoonBit 的跨平台 Glob 路径匹配和文件检索库。

它提供：

- `compile_pattern` / `CompiledPattern`：编译一次，循环复用；
- `glob_with_options`：文件系统搜索、隐藏项、深度和排序控制；
- `GlobQuery` / `GlobPipeline`：组合 include/exclude、限制和报告；
- `GlobRules`：类似 `.gitignore` 的规则解析；
- `PathIndex`：内存路径索引；
- `explain_pattern`、`PatternCache` 和确定性 benchmark workload。

基础用法：

```moonbit nocheck
let pattern = @glob.compile_pattern("src/**/*.mbt")?
let paths = ["src/main.mbt", "src/core/parser.mbt", "README.md"]
let matched = @glob.filter_compiled_patterns([pattern], paths)
```

文件系统用法：

```moonbit nocheck
let options = @glob.GlobOptions::default().files_only().sorted()
let files = @glob.glob_with_options(".", "**/*.mbt", options)?
```

CLI 用法：

```bash
moon run cmd/main "**/*.mbt"
moon run cmd/main "src/**/*.mbt" "src"
```

完整语义、错误处理、Windows 安装、基准数据、许可证和 CI 验收命令请阅读 [README.md](README.md)。

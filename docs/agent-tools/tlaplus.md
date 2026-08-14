# TLA+ 工具链

## 分层职责

```text
tree-sitter-tlaplus     TLA+/PlusCal 高亮、折叠和局部语法结构
tla2tools.jar           SANY、TLC 和 PlusCal translator
Graphviz                TLC 可达状态图 DOT/SVG/PNG 渲染
Gentlewind tlaplus      diagnostics、quickfix、结果窗和工作台
TraeX                   规格解释、模型设计和反例分析
TLAPS / Apalache        可选证明与符号模型检查，不是基础依赖
```

TLA+ 不是普通的“Tree-sitter + Mason LSP”语言。Gentlewind 不通过 Mason 安装
实验性 language server，而是直接调用官方工具链，并保留完整原始输出。

## 固定工具版本

工具脚本位于：

```text
tools/tlaplus-toolchain.sh
```

它默认固定官方稳定版 `tla2tools.jar v1.7.4`，并校验 SHA256：

```text
936a262061c914694dfd669a543be24573c45d5aa0ff20a8b96b23d01e050e88
```

安装位置：

```text
~/.local/share/gentlewind/tlaplus/v1.7.4/tla2tools.jar
```

安装和检查：

```bash
./tools/tlaplus-toolchain.sh install
./tools/tlaplus-toolchain.sh health
```

可以用 `TLA2TOOLS_JAR` 显式覆盖 JAR 路径；覆盖版本由使用者负责验证。配置不会
静默追踪 GitHub latest 或预发布版本。

基础依赖：

```bash
brew install openjdk graphviz
```

## CLI 验证

```bash
# SANY：语法、语义和 level checking
./tools/tlaplus-toolchain.sh check Spec.tla

# TLC：默认读取同名 Spec.cfg
./tools/tlaplus-toolchain.sh model-check Spec.tla

# 指定其他模型配置
./tools/tlaplus-toolchain.sh model-check Spec.tla Small.cfg

# 运行 5 秒随机 simulation
./tools/tlaplus-toolchain.sh smoke Spec.tla Spec.cfg 5

# PlusCal 翻译
./tools/tlaplus-toolchain.sh translate Spec.tla

# 生成 DOT、SVG 和 PNG 状态图
./tools/tlaplus-toolchain.sh graph Spec.tla
```

生成物写入项目根目录的 `.tla-cache/`。该目录已被 `.gitignore` 忽略。
PlusCal 翻译前的 `.tla`、已有 `.cfg` 和 translator 生成的 `.old` 文件也会保存在
该目录中。

## 文件类型

- `*.tla` 显式识别为 `tlaplus`。
- `*.cfg` 不会被全局覆盖。
- 只有存在同名 `.tla`，或前 80 行包含 TLC 配置指令时，才识别为
  `tlaplusconfig`。

Tree-sitter 使用 `nvim-treesitter` 已维护的 `tlaplus` parser 和 queries。
源码保持 ASCII TLA+ 运算符，不安装自动把 ASCII 改写成 Unicode 的插件。

## Neovim 命令

```text
:TlaInstall
:TlaHealth
:TlaCheck
:TlaModelCheck [cfg]
:TlaSmoke [cfg] [seconds]
:TlaTranslate
:TlaGraph [cfg]
:TlaCancel
:TlaWorkbenchOpen
:TlaWorkbenchClose
:TlaWorkspace
:TlaAgentAsk [explain|model|debug]
:TlaAgentExplain
:TlaAgentModel
:TlaAgentDebug
```

行为约束：

- 保存 `.tla` 时只运行较轻量的 SANY。
- 如果同一 buffer 正在执行 TLC，保存不会中断该任务。
- TLC、smoke 和 graph 必须显式执行。
- 新任务会停止同一规格的旧任务。
- `:TlaCancel` 请求终止当前任务。
- `VimLeavePre` 只发送终止信号，不同步等待 Java，避免退出 Neovim 卡住。
- PlusCal 翻译要求 `.tla` 和当前 `.cfg` buffer 都已保存，成功后重新读取文件并运行
  SANY。
- SANY/TLC 的源码位置进入 diagnostics 和 quickfix；完整原始输出保留在结果窗。

## Buffer 键位

`maplocalleader` 为 `,`：

| 键位 | 动作 |
| --- | --- |
| `,c` | SANY 检查 |
| `,m` | TLC 完整模型检查 |
| `,s` | TLC smoke test |
| `,t` | PlusCal 翻译 |
| `,g` | 生成并显示状态图 |
| `,x` | 停止当前任务 |
| `,w` / `,q` | 打开 / 关闭结果工作台 |
| `,a` | 携带文件、诊断和最近输出请求 TraeX |
| `,h` | 工具链健康检查 |
| `,o` | 打开 Kitty + Zellij 工作台 |

## 分层工作台

可以从 TLA+ buffer 执行：

```text
:TlaWorkspace
```

或者：

```bash
./tools/tlaplus-workbench.sh path/to/Spec.tla
```

布局：

```text
Kitty
├─ 上部 68%：Neovim
│   ├─ 左侧：TLA+ / PlusCal 源码
│   └─ 右侧：SANY/TLC 输出或 TLC 状态图
└─ 下部 32%：Zellij
    ├─ agent：TraeX
    ├─ tools：TLC shell / shell / lazygit
    └─ logs：Neovim 日志
```

在 Kitty 中，状态图 PNG 由 `kitty +kitten icat` 显示。其他终端会使用系统外部
查看器打开 SVG/PNG。Agent、长时间 TLC 和 Git 保留在 Zellij，不占用代码和
可视化区域。

## Agent 验证闭环

Agent 应遵循：

1. 阅读 `.tla`、对应 `.cfg` 和最近的 SANY/TLC 输出。
2. 先修复 parse、semantic 和 level 错误。
3. 明确 TLC 的常量赋值、状态空间、worker、simulation 或 model-check 模式。
4. 出现 counterexample 时，定位第一个错误状态和导致它的 action。
5. 修改后重新运行 SANY 和 TLC。
6. 不得把“有限模型未发现反例”表述为一般性证明。
7. 不得伪造 SANY、TLC、TLAPS 或 Apalache 输出。

`:TlaAgent*` 只把上下文预填到 Agentic/TraeX，不自动发送。也可以直接在
Zellij 的 `agent` tab 使用 TraeX，并让它调用同一个工具脚本。

## 可选高级工具

- **Apalache**：适合 SMT/符号模型检查，和 TLC 结论互补。验证具体项目需求后再装。
- **TLAPS**：适合 TLA+ 定理证明。Apple Silicon 原生包目前主要来自预发布通道，
  不作为基础环境依赖。
- **MCP**：官方 VS Code TLA+ MCP 当前依赖 VS Code extension API，standalone
  仍未成为稳定入口。Gentlewind 暂不把它配置给 TraeX。

未来如果增加独立 MCP，应包装 `tlaplus-toolchain.sh` 的结构化输出，而不是复制一套
不同的 SANY/TLC 执行逻辑。

## 结论边界

- SANY 成功：规格能被解析，并通过相应语义/level 检查。
- TLC model check 成功：在当前有限配置中未发现反例。
- TLC smoke 成功：在给定时间的随机行为中未发现反例。
- 上述结果都不等同于 TLAPS 证明。

## 参考

- https://github.com/tlaplus/tlaplus
- https://github.com/tlaplus-community/tree-sitter-tlaplus
- https://github.com/tlaplus/vscode-tlaplus

# Lean 4 工具链

## 分层职责

```text
elan             Lean 版本管理
lean-toolchain   项目版本声明
lake             项目、依赖、构建和 language server
mathlib          形式化数学基础库
lean.nvim        Neovim Infoview、Unicode、交互式 goal
lean-lsp-mcp     Agent 的 goal、诊断、搜索和验证工具
Lean Skills      Agent 的证明方法与安全约束
```

不要让 Mason 安装 Lean language server。Lean 4 server 属于项目工具链，应由
`elan` 和 `lean-toolchain` 保证版本一致。

## 环境检查

```bash
elan --version
lean --version
lake --version
```

macOS 使用 Homebrew 时应安装 formula：

```bash
brew install elan-init
elan default stable
```

不要执行 `brew install --cask elan`。这个同名 cask 是 MPI 的音视频标注应用
ELAN，不是 Lean theorem prover 的版本管理器。

Homebrew formula 的 shim 位于：

```text
/opt/homebrew/bin/elan
/opt/homebrew/bin/lean
/opt/homebrew/bin/lake
```

官方安装脚本则通常使用 `~/.elan/bin`。Gentlewind 会补充下面的用户目录，同时保留
Homebrew 路径：

```text
~/.local/bin
~/.elan/bin
```

因此从 GUI 或 Zellij 启动 Neovim 时也应该能找到 `traex`、`uvx`、`lean` 和
`lake`。

## 创建 Mathlib 项目

```bash
lake +leanprover-community/mathlib4:lean-toolchain new formal math
cd formal
lake exe cache get
lake build
```

`lake exe cache get` 会下载 Mathlib 预编译缓存，可以避免第一次构建耗时过长。

## Agent 能力

推荐 MCP：

```bash
traex mcp add lean-lsp -- uvx lean-lsp-mcp
```

关键工具：

- `lean_goal`：读取光标位置的证明状态。
- `lean_diagnostic_messages`：读取当前文件错误与警告。
- `lean_code_actions`：获取 `simp?`、`exact?` 等 Try This。
- `lean_multi_attempt`：并行验证多个 tactic。
- `lean_local_search`：在项目和本地 Mathlib 中搜索。
- `lean_leansearch` / `lean_loogle`：外部 Mathlib 搜索。
- `lean_verify`：检查 `sorryAx`、额外公理和危险设置。
- `lean_profile_proof`：分析慢证明。

## 证明闭环

Agent 应遵循：

1. 读取当前 goal。
2. 一次只尝试一个证明步骤。
3. 出错时依次处理语法、类型、未解 goal、linter。
4. 搜索 Mathlib 后再自行重造 lemma。
5. 使用 `lean_multi_attempt` 比较候选 tactic。
6. 使用 `lean_diagnostic_messages` 做局部反馈。
7. 完成后运行 `lean_verify` 和 `lake build`。
8. 不允许把新的 `sorry`、`axiom` 或 `sorryAx` 当成完成状态。

## Neovim IDE 目标

Lean 模块位于：

```text
fnl/gentlewind/modules/langs/lean.fnl
```

它已经提供：

- `Julian/lean.nvim` 与项目级 `leanls`。
- 右侧 32% 宽度的 Infoview。
- Unicode abbreviation、语义高亮、inlay hints 和 proof progress。
- 当前 goal、term goal、diagnostics、suggestion 和 restart-file 操作。
- Kitty 上部的 Neovim 只保留“Lean 源码 + Infoview/ProofWidgets”。
- Kitty 下部由 Zellij 承载 TraeX、shell/build、lazygit 和 LSP log。
- 一键把当前文件、视觉选区、诊断和 goal 预填到 Agent prompt。
- Explain、Suggest、Solve 三种 Agent 工作模式。
- Lake build 终端入口。
- 打开 Neovim Workbench 或请求 Agent 时，把当前 tab 的 cwd 对齐到最近的
  `lakefile.toml`、`lakefile.lean` 或 `lean-toolchain` 根目录，确保 TraeX 与 MCP
  使用正确项目上下文；其他 tab 和全局 cwd 不受影响。

模块不通过 Mason 安装 Lean，也不启用实验性 Tree-sitter parser。

## Lean 分层工作台

`lean.nvim` 已开启终端图形支持。SVG 由 `resvg` 转换，并通过 Kitty Graphics
Protocol 显示在 Infoview 中。

推荐直接启动完整工作台：

```bash
cd ~/workspace/bcedd-math
lean-workbench BceddMath/TierA.lean
```

也可以从当前 Lean buffer 执行：

```text
:LeanWorkspace
```

或按 `,o`。`:LeanGraphics` 是兼容别名。

工作台结构：

```text
Kitty
├─ 上部 68%：Neovim
│   ├─ 左侧：Lean 源码
│   └─ 右侧：Infoview / ProofWidgets
└─ 下部 32%：Zellij
    ├─ agent：TraeX
    ├─ tools：shell / build / lazygit（stacked panes）
    └─ logs：~/.local/state/nvim/lsp.log
```

Kitty 保证 Neovim 能直接使用图形协议；Zellij 仍被完整保留，但只承载非图形工具。
同一项目会复用稳定命名的 Zellij session。当前文件有未保存修改时，工作台命令会拒绝
启动，避免另一个 Neovim 读取旧版本。

Kitty 支持 lean.nvim 使用的 Kitty Graphics Protocol。
当前 lean.nvim 检测到 `ZELLIJ` 时会主动关闭图片传输，避免转义序列污染窗口；
这不会影响普通 goal、diagnostics、文本 widget 和 Agent 工作流。

环境检查：

```bash
resvg --version
test -n "$KITTY_WINDOW_ID" && echo "Kitty graphics mode"
test -n "$ZELLIJ" && echo "Zellij text mode"
```

## 浏览器 Lean Live

公网页面 `https://live.lean-lang.org/` 提供 Monaco 编辑器和浏览器版
Infoview。Gentlewind 提供单向打开入口：

```text
:LeanLive
:'<,'>LeanLive
```

- 普通执行会把当前 Lean buffer 编码进 URL 的 `#code=`。
- Visual 模式 `,l` 会发送当前文件的 `import` 行和选区，适合把一个 theorem
  作为最小示例打开。
- URL fragment 不会发给普通 HTTP 服务端，但浏览器中的 Lean server 仍在远端运行；
  不要发送包含敏感源码或数据的内容。
- 公网 Lean Live 使用服务器预装的 Lean/Mathlib 项目，不会读取本地
  `lean-toolchain`、`.lake` 或自定义模块，也不会把浏览器修改同步回本地。

因此它适合快速试验、分享 MWE 和查看完整 Web ProofWidgets；`bcedd-math`
正式开发、构建与验证仍应留在本地 Neovim。

## IDE 命令

```text
:LeanWorkbenchOpen
:LeanWorkbenchClose
:LeanAgentAsk [explain|suggest|solve]
:LeanAgentExplain
:LeanAgentSuggest
:LeanAgentSolve
:LeanRecover
:LeanLive
:LeanGraphics
:LeanWorkspace
:LeanBuild
```

`LeanAgent*` 只会预填 Agentic prompt，不自动发送。补充上下文后使用 Agentic 的
`Shift-Enter` 或 `Ctrl-s` 提交。

`:LeanRecover` 会根据当前状态选择恢复方式：

- `leanls` 仍连接时，只重启当前文件的 Lean worker。
- Infoview 显示 `🪦 The Lean language server is dead.`、`leanls` 已脱附时，
  重新启用 `leanls` 并附着当前 buffer，不需要退出 Neovim。

## Lean buffer 键位

`maplocalleader` 为 `,`：

| 键位 | 作用 |
|---|---|
| `,i` | 开关 Infoview |
| `,p` | 暂停或恢复 pin |
| `,x` / `,c` | 添加或清除 pin |
| `,s` | 接受第一条 suggestion |
| `,<Tab>` | 跳转 Infoview |
| `,\` | Unicode abbreviation 反查 |
| `,r` | 智能恢复 `leanls`，或重启当前 Lean 文件 worker |
| `,g` / `,t` | goal / term goal |
| `,v` | Infoview view options |
| `,w` / `,q` | 在当前 Neovim 打开或关闭“源码 + Infoview” |
| `,a` | Normal 模式打开 Lean Agent 菜单；Visual 模式直接携带选区请求 tactic 建议 |
| `,l` | 在 Lean Live 打开当前文件；Visual 模式打开 imports 与选区 |
| `,o` | 打开完整 Kitty + Zellij Lean 工作台 |
| `,b` | `lake build` |
| `,h` | `checkhealth lean` |
| `K` | Lean 交互式 hover |

Workbench 可见窗口结构：

```text
Neovim：源码 + 右侧 Infoview
Kitty 下部：Zellij Agent/Tools/Logs
```

## 验证

```text
:checkhealth lean
:LspInfo
:LeanGoal
:LeanInfoviewToggle
```

如果 Infoview 显示 language server 墓碑，先运行：

```text
:LeanRecover
```

恢复后移动一次源码游标即可刷新当前 goal。若 10 秒后仍未重新连接，再检查
`:checkhealth lean`、`:messages` 和 `~/.local/state/nvim/lsp.log`。

命令行：

```bash
lake build
```

TraeX：

```text
/skills
/mcp verbose
```

确认官方 `lean-proof` Skill 可见，并能调用 `lean_goal`。

最小验收应同时确认：

- `leanls` attach 到 Lean buffer。
- Infoview 能显示当前 hypotheses 和 target。
- Kitty 上部只包含 Neovim，Neovim 内只包含源码与 Infoview。
- Kitty 下部 Zellij 能看到 agent/tools/logs 三个 tab。
- `:LeanWorkbenchClose` 能恢复源码单窗。

## 参考

- https://lean-lang.org/install/
- https://github.com/leanprover/skills
- https://github.com/Julian/lean.nvim
- https://github.com/oOo0oOo/lean-lsp-mcp
- https://github.com/leanprover-community/mathlib4

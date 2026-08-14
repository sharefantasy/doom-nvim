# Agent 工具知识库

本目录描述 Gentlewind 中 Agent、MCP、Skills 与专业工具链的职责边界。目标是让
后续设计和排障先复用已验证的架构，而不是重新猜测 CLI 名称、配置来源和加载顺序。

## 当前架构

```text
Kitty Lean Workspace
  ├─ top 68%: Neovim
  │   └─ Lean source | lean.nvim Infoview / ProofWidgets
  └─ bottom 32%: Zellij
      ├─ agent: traex
      ├─ tools: shell / build / lazygit
      └─ logs: nvim LSP log

Kitty TLA+ Workspace
  ├─ top 68%: Neovim
  │   └─ TLA+ source | SANY/TLC results / state graph
  └─ bottom 32%: Zellij
      ├─ agent: traex
      ├─ tools: TLC shell / shell / lazygit
      └─ logs: nvim log

Neovim optional Agent integration
  ├─ agentic.nvim ──stdio/ACP──> traex acp serve
  └─ sidekick.nvim ──terminal──> traex

TraeX
  ├─ ~/.trae/traecli.toml
  ├─ ~/.trae/skills/
  └─ MCP: uvx lean-lsp-mcp
```

## 设计原则

- Neovim 内只使用 `traex`，不再把旧 Coco 作为 Agent provider。
- 编辑器交互走 ACP；专业工具调用走 MCP；领域方法和工作流走 Skill。
- Lean 主工作台中 Neovim 只负责“代码 + 可视化”；Agent、构建和 Git 放在下方 Zellij。
- TLA+ 主工作台采用同样分层；SANY/TLC 原始输出是验证事实，诊断和图形只是交互视图。
- `agentic.nvim` 保留为通用/备用集成，但 `:LeanWorkbenchOpen` 不会自动打开它。
- Agent 修改代码后仍需走项目自身的编译和验证命令。
- Lean 版本由项目 `lean-toolchain` 管理，不由 Mason 或 Neovim 固定。
- 数值实验与形式化证明分目录、分运行时管理。

## 入口

- [TraeX 与 Neovim 集成](traex.md)
- [Lean 4 工具链](lean.md)
- [TLA+ 工具链](tlaplus.md)
- [形式化与科学计算工作流](scientific-computing.md)

## 快速检查

```bash
traex --version
traex mcp list
uvx lean-lsp-mcp --help
elan --version
lean --version
lake --version
./tools/tlaplus-toolchain.sh health
```

进入 TraeX 后还可以使用：

```text
/status
/skills
/mcp verbose
```

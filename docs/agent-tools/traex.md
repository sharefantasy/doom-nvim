# TraeX 与 Neovim 集成

## 命令选择

Gentlewind 明确使用 `traex`：

- `traex` 是新版 TRAE CLI 的无冲突入口。
- 某些机器上的 `traecli` 仍可能指向旧 Coco，因此不要在 Neovim 配置中依赖它。
- Agentic 通过 stdio 启动 `traex acp serve`。
- Sidekick 直接启动 `traex` 的交互式终端。

对应的 Fennel 配置位于：

- `fnl/user/config.fnl`
- `fnl/gentlewind/modules/config/dev_tools/init.fnl`

## 配置来源

TraeX 的用户配置默认位于：

```text
~/.trae/traecli.toml
~/.trae/skills/
```

工作区可以补充：

```text
<workspace>/.trae/traecli.toml
<workspace>/.trae/skills/
<workspace>/.trae/mcp.json
```

不要在仓库里提交用户 token、私有 endpoint 或完整的个人配置副本。

## ACP

ACP 是 Neovim 与 TraeX 的编辑器集成协议：

```bash
traex acp serve
```

它通过标准输入输出通信，由 `agentic.nvim` 负责启动，不需要人工先开后台服务。

修改 Agent provider 后，旧 Agentic session 不会自动迁移。应关闭旧 session，再创建新
session，以确保实际进程是 `traex acp serve`。

## MCP

MCP 用于向 TraeX 提供专业工具。常用管理命令：

```bash
traex mcp list
traex mcp get <name>
traex mcp add <name> -- <command> ...
traex mcp remove <name>
```

Lean 推荐配置：

```bash
traex mcp add lean-lsp -- uvx lean-lsp-mcp
```

如需固定版本，在 `~/.trae/traecli.toml` 中使用：

```toml
[mcp_servers.lean-lsp]
command = "uvx"
args = ["--from", "lean-lsp-mcp==0.29.0", "lean-lsp-mcp"]
enabled = true
startup_timeout_sec = 60.0
tool_timeout_sec = 60.0
default_tools_approval_mode = "prompt"
```

验证：

```bash
traex mcp list
traex mcp get lean-lsp
```

进入 TraeX 后运行 `/mcp verbose`，确认工具列表中包含 `lean_goal`、
`lean_diagnostic_messages`、`lean_multi_attempt` 和 `lean_verify`。

## Skills

TraeX 用户级 Skill 放在：

```text
~/.trae/skills/<skill>/SKILL.md
```

查看当前可见 Skill：

```text
/skills
```

Lean 首选官方 `leanprover/skills`：

```bash
python3 ~/.trae/skills/.system/skill-installer/scripts/install-skill-from-github.py \
  --repo leanprover/skills \
  --path skills/lean-proof skills/lean-mwe skills/mathlib-build
```

安装后重启 TraeX 和 Neovim 中的 Agentic session。

## Neovim 窗口策略

通用 Neovim 会话中，Agentic 默认位于底部：

- Chat 占底部左侧。
- Prompt 占底部右侧。
- 右侧空间留给 Lean Infoview、Aerial 或其他语言侧栏。
- `<C-h/j/k/l>` 负责 Neovim 窗口和 Zellij pane 的统一导航。
- `<leader>a` 打开 Agent Hydra；其中 `l` 可以在底部、右侧、左侧布局间轮换。

Lean 专用工作台采用更严格的职责划分：

- Neovim 上部只显示 Lean 源码与 Infoview/ProofWidgets。
- TraeX、shell、build、git 和 LSP log 全部放入下方 Zellij。
- `:LeanWorkspace` 或 `lean-workbench <file>` 启动该布局。
- `:LeanAgent*` 命令仍可按需调用 Neovim 内 Agentic，但不会随
  `:LeanWorkbenchOpen` 自动出现。

## 排障顺序

1. `command -v traex` 和 `traex --version`。
2. `traex mcp list`。
3. TraeX 中 `/status`、`/skills`、`/mcp verbose`。
4. 确认 Neovim 启动进程是 `traex acp serve`，而不是旧 `coco acp serve`。
5. 检查 `~/.local/bin` 是否在 Neovim 的 `vim.env.PATH`。
6. 修改 Fennel 后运行 `./tools/compile-fennel.sh`。

# Gentlewind 文档库

这里保存影响 Gentlewind 设计、开发和日常维护的长期知识。配置仍以
`fnl/` 下的 Fennel 源码为准；文档用于解释设计决策、外部工具边界和可复现的
验证流程。

## 索引

- [Agent 工具知识库](agent-tools/README.md)
  - [TraeX 与 Neovim 集成](agent-tools/traex.md)
  - [Lean 4 工具链](agent-tools/lean.md)
  - [TLA+ 工具链](agent-tools/tlaplus.md)
  - [形式化与科学计算工作流](agent-tools/scientific-computing.md)

## 维护规则

1. 文档只记录可复用的项目事实，不保存 token、账号或内部敏感配置。
2. 命令示例使用通用路径，不写个人机器的绝对目录。
3. 外部工具升级后，先验证实际 `--help`、版本和运行结果，再更新文档。
4. Fennel 配置变更后必须运行 `./tools/compile-fennel.sh`。
5. 发现文档与代码不一致时，以当前 Fennel 源码和可复现输出为准，并同步修正文档。

# Doom Nvim Fennel 重写项目

本项目已将 Doom Nvim 从 Lua 重写为 Fennel 语言，使用 Aniseed 框架进行编译和管理。

## 🚀 快速开始

### 1. 安装 Aniseed

确保你的 Neovim 已经安装了 Aniseed 插件。在 `lazy.nvim` 中添加：

```lua
{
  "Olical/aniseed",
  ft = "fennel",
  dependencies = {
    "Olical/nfnl",
  },
}
```

### 2. 编译 Fennel 代码

使用提供的编译脚本：

```bash
./tools/compile-fennel.sh
```

或者手动编译单个文件：

```bash
nvim --headless --clean -c "
  set rtp+=~/.local/share/nvim/lazy/aniseed
  lua require('aniseed.compile').compile('fnl/doom/core/init.fnl', 'lua/doom/core/init.lua')
  quit
"
```

### 3. 启动 Neovim

编译完成后，正常使用 Neovim：

```bash
nvim
```

## 📁 项目结构

```
fnl/                    # Fennel 源代码
├── doom/
│   ├── core/          # 核心模块
│   ├── modules/       # 功能模块
│   ├── services/      # 服务层
│   └── utils/         # 工具函数
└── user/              # 用户配置
lua/                    # 编译后的 Lua 代码（自动生成）
```

## 🔧 开发指南

### 添加新模块

1. 在 `fnl/doom/modules/` 下创建新的 Fennel 文件
2. 遵循模块标准结构：

```fennel
(local my-module {})

(my-module.packages {})
(my-module.configs {})
(my-module.settings {})
(my-module.autocmds [])
(my-module.cmds [])
(my-module.binds [])

{: packages my-module.packages
 : configs my-module.configs
 : settings my-module.settings
 : autocmds my-module.autocmds
 : cmds my-module.cmds
 : binds my-module.binds}
```

### 用户配置

用户配置现在使用 Fennel 编写：

- `fnl/user/config.fnl` - 用户配置文件
- `fnl/user/modules.fnl` - 模块启用配置

### 实时开发

使用 Conjure 进行交互式开发：

1. 打开任何 `.fnl` 文件
2. 运行 `:ConjureConnect`
3. 使用 `<localleader>ee` 评估代码块

## 🎯 特性

### ✅ 已完成

- [x] 核心框架重写
- [x] 模块系统迁移
- [x] 服务层重构
- [x] 语言支持模块
- [x] 功能模块
- [x] 编译脚本
- [x] 用户配置系统

### 🚧 进行中

- [ ] 完整测试覆盖
- [ ] 性能优化
- [ ] 文档完善

### 📋 计划

- [ ] 更多语言支持
- [ ] 插件生态集成
- [ ] REPL 增强

## 🛠️ 编译选项

Aniseed 配置在 `.aniseed.fnl` 中：

```fennel
{:compile-path "lua"
 :fnl-path "fnl"
 :compiler {:metadata true
            :useMetadata true}}
```

## 📚 学习资源

- [Fennel 语言指南](https://fennel-lang.org/)
- [Aniseed 文档](https://github.com/Olical/aniseed)
- [Conjure 文档](https://github.com/Olical/conjure)

## 🤝 贡献

欢迎贡献！请：

1. Fork 项目
2. 创建特性分支
3. 提交 Fennel 代码
4. 确保通过编译测试
5. 提交 Pull Request

## 📄 许可证

MIT License - 详见 LICENSE 文件

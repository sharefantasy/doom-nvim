# Doom Nvim 架构概述

## 项目概述

Doom Nvim 是一个受 doom-emacs 启发的 Neovim 配置框架，提供模块化、可配置的 Neovim 配置方案。项目采用模块化架构，支持特性模块和语言模块的动态加载，具有快速启动、稳定更新、可扩展性强等特点。

### 核心架构

- **模块化设计**: 分为 `features`（功能模块）和 `langs`（语言模块）两类
- **插件管理**: 使用 lazy.nvim 进行插件管理，支持延迟加载
- **配置系统**: 通过 `config.lua` 和 `modules.lua` 进行用户配置
- **用户扩展**: 支持用户自定义模块覆盖默认模块
- **双语言支持**: 正在进行 Fennel 重写，支持 Lua 和 Fennel 两种开发语言

## 项目结构

```
├── fnl/                        # Fennel 源代码目录（新增）
│   ├── doom/                   # Fennel 核心框架代码
│   │   ├── core/              # 核心功能（配置、模块、命令等）
│   │   ├── modules/           # 内置模块
│   │   │   ├── features/     # 功能模块（35+）
│   │   │   └── langs/        # 语言模块（20+）
│   │   ├── services/         # 服务层（自动命令、键映射等）
│   │   └── utils/            # 工具函数
│   ├── gentlewind/           # Gentlewind 主题（Fennel）
│   ├── user/                 # 用户自定义模块（Fennel）
│   │   ├── config.fnl        # 用户配置文件（Fennel）
│   │   └── modules.fnl       # 模块启用配置（Fennel）
│   └── init.fnl              # 主入口文件（Fennel）
├── lua/doom/                   # Lua 核心框架代码（将逐步迁移到fnl）
│   ├── core/                   # 核心功能
│   ├── modules/                # 内置模块
│   ├── services/               # 服务层
│   ├── utils/                  # 工具函数
│   └── tools/                  # 开发工具
├── lua/user/                   # 用户自定义模块目录（Lua）
├── config.lua                  # 用户配置文件（Lua）
├── modules.lua                 # 模块启用配置（Lua）
├── lazy-lock.json              # 插件锁定文件
├── .aniseed.fnl               # Fennel 编译配置
├── FENNEL_MIGRATION.md        # Fennel 迁移文档
├── FENNEL_REWRITE_SUMMARY.md  # Fennel 重写总结
└── $HOME/.local/share/lazy/   # lazy.nvim 插件存储目录（运行时生成）
```

## 构建与命令

### 安装命令

```bash
# 自动安装
curl -s https://raw.githubusercontent.com/doom-neovim/doom-nvim/main/tools/install.sh | sh

# 手动安装
git clone https://github.com/doom-neovim/doom-nvim.git ~/.config/nvim
```

### 开发命令

```bash
# 插件管理（lazy.nvim）
:Lazy                # 打开 lazy.nvim 插件管理界面
:Lazy sync            # 同步所有插件
:Lazy update          # 更新插件
:Lazy install         # 安装缺失插件

# Doom 专用命令
:DoomCheckUpdates    # 检查更新
:DoomReload          # 重载配置

# Fennel 开发命令
./tools/compile-fennel.sh    # 编译 Fennel 代码到 Lua
./tools/test-fennel.sh        # 测试 Fennel 代码
```

### 插件存储管理

项目使用 lazy.nvim 管理插件，所有下载的插件存储在 `$HOME/.local/share/lazy/` 目录中：

```
$HOME/.local/share/lazy/
├── lazy.nvim/          # lazy.nvim 自身
├── [插件名称]/         # 各个插件的源代码
│   ├── plugin/         # 插件主目录
│   └── ...
└── ...
```

插件管理特点：
- **延迟加载**: 插件按需加载，优化启动性能
- **版本锁定**: 通过 lazy-lock.json 锁定插件版本
- **自动管理**: 自动处理插件依赖关系
- **缓存机制**: 插件编译缓存提高加载速度

### 代码质量工具

```bash
# Lua 代码格式化（stylua）
stylua --config-path .stylua.toml .

# Lua 静态检查（luacheck）
luacheck .

# Fennel 代码格式化（fnlfmt）
fnlfmt --write fnl/

# Fennel 语法检查（fennel）
fennel --compile fnl/doom/core/init.fnl
```

## 代码规范

### 格式化规则

#### Lua 代码规范
- **缩进**: 2 个空格
- **行宽**: 120 字符
- **引号**: 优先使用双引号
- **命名**: 
  - 变量名: `snake_case`
  - 函数名: `snake_case`
- **工具**: 使用 stylua 进行格式化，luacheck 进行静态检查

#### Fennel 代码规范
- **缩进**: 2 个空格
- **行宽**: 120 字符
- **括号**: 使用标准 Lisp 括号风格
- **命名**:
  - 变量名: `kebab-case`
  - 函数名: `kebab-case`
- **注释**: 使用 `;;` 单行注释，`;;` 块注释
- **工具**: 使用 fnlfmt 进行格式化，fennel 进行语法检查

### 模块开发规范

#### Lua 模块开发
1. 模块文件必须返回模块表
2. 模块应包含 `packages`、`configs`、`settings` 等标准字段
3. 使用 `doom.use_package()` 添加插件
4. 使用 `doom.use_keybind()` 添加键绑定
5. 使用 `doom.use_autocmd()` 添加自动命令

#### Fennel 模块开发
1. 模块文件必须返回模块表
2. 使用 `(module module-name)` 声明模块
3. 模块结构：`{:packages [] :configs {} :settings {}}`
4. 使用 `(doom.use-package ...)` 添加插件
5. 使用 `(doom.use-keybind ...)` 添加键绑定
6. 使用 `(doom.use-autocmd ...)` 添加自动命令

## 测试框架

项目当前未集成专门的测试框架，但提供以下质量保证机制：

- **静态代码分析**: luacheck 检查 Lua 代码质量
- **代码格式化**: stylua 确保代码风格一致性
- **插件锁定**: lazy-lock.json 确保插件版本稳定性
- **错误日志**: 详细的错误日志记录在 `~/.local/share/nvim/doom.log`
- **插件缓存**: lazy.nvim 插件缓存存储在 `$HOME/.local/share/lazy/`

## 安全配置

### 安全考虑

1. **插件安全**: 所有插件通过官方仓库获取，使用 commit SHA 锁定版本
2. **代码执行**: 配置文件中的代码执行受限于 Neovim 沙箱环境
3. **网络访问**: 插件安装和更新需要网络访问，建议审查插件来源
4. **文件系统**: 配置和缓存文件存储在标准 XDG 目录中
5. **插件隔离**: lazy.nvim 将插件隔离存储在 `$HOME/.local/share/lazy/` 目录，避免冲突

### 数据保护

- 用户配置存储在 `~/.config/nvim/`
- 插件数据存储在 `~/.local/share/nvim/`
- 缓存文件存储在 `~/.cache/nvim/`
- 日志文件包含错误信息，避免记录敏感数据

## 配置管理

### 环境配置

```lua
-- config.lua 关键配置
doom.freeze_dependencies = false  -- 是否锁定插件版本
doom.logging = 'trace'            -- 日志级别
doom.indent = 2                   -- 缩进设置
doom.colorscheme = "gruvbox"     -- 主题设置
```

### 模块配置

```lua
-- modules.lua 模块启用
return {
  features = {
    'lsp',           -- 代码补全
    'telescope',     -- 模糊搜索
    'whichkey',      -- 键绑定提示
    -- ... 其他功能模块
  },
  langs = {
    'lua',           -- Lua 语言支持
    'python',        -- Python 语言支持
    'javascript',    -- JavaScript 语言支持
    -- ... 其他语言模块
  }
}
```

### 用户扩展

用户可通过 `lua/user/modules/` 目录添加自定义模块或覆盖默认模块：

```lua
-- lua/user/modules/features/my_feature/init.lua
local my_feature = {}

my_feature.packages = {}
my_feature.configs = {}
my_feature.settings = {}

return my_feature
```

## 开发建议

### 通用开发建议
1. **模块化开发**: 遵循模块架构，保持模块独立性
2. **延迟加载**: 利用 lazy.nvim 的延迟加载机制优化启动性能，插件存储在 `$HOME/.local/share/lazy/`
3. **错误处理**: 使用 `utils.safe_require()` 进行安全的模块加载
4. **性能监控**: 使用内置的性能分析工具监控启动时间
5. **文档完善**: 为自定义模块添加详细文档和配置说明

### Fennel 开发建议
1. **编译流程**: 修改 Fennel 代码后需运行 `./tools/compile-fennel.sh` 编译到 Lua
2. **语法检查**: 使用 `fennel --compile` 检查语法错误
3. **代码格式化**: 使用 `fnlfmt` 保持代码风格一致
4. **模块结构**: 遵循 Fennel 模块规范，使用 kebab-case 命名
5. **迁移策略**: 新功能优先使用 Fennel 开发，逐步迁移现有 Lua 代码

## 故障排除

### 通用问题
- **启动问题**: 检查 `doom.log` 日志文件
- **插件问题**: 运行 `:Lazy sync` 同步插件
- **配置问题**: 验证 `config.lua` 和 `modules.lua` 语法
- **性能问题**: 使用内置 profiler 分析启动时间

### Fennel 相关问题
- **编译错误**: 检查 Fennel 语法，使用 `fennel --compile` 验证
- **模块加载失败**: 确保 Fennel 代码已正确编译到 Lua
- **编译后无效**: 检查编译输出目录和文件权限
- **混合语言问题**: 确保 Lua 和 Fennel 模块命名不冲突
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- 基础配置
vim.opt.colorcolumn = "120"
vim.g.skip_ts_context_commentstring_module = true
doom.indent = 2
doom.core.treesitter.settings.show_compiler_warning_message = false
doom.core.reloader.settings.reload_on_save = true
doom.colorscheme = "gruvbox"
doom.freeze_dependencies = false

-- 加载用户配置模块
require("user.modules.config.editor").setup()
require("user.modules.config.ui").setup()
require("user.modules.config.dev_tools").setup()
require("user.modules.config.lsp").setup()
require("user.modules.config.search").setup()

doom.use_package { "Olical/nfnl", ft = "fennel" }
doom.use_package "Olical/aniseed"

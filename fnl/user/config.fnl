;; Example Fennel-based config.lua for Gentlewind Nvim
;; This replaces the traditional Lua config.lua

;; Configure Gentlewind settings
;; 基础配置
(set vim.g.loaded_netrw 1)
(set vim.g.loaded_netrwPlugin 1)
(set vim.opt.colorcolumn "120")
(set vim.g.skip_ts_context_commentstring_module true)
(set! gentlewind.indent 2)
(set! gentlewind.core.treesitter.settings.show_compiler_warning_message false)
(set! gentlewind.core.reloader.settings.reload_on_save true)
(set! gentlewind.colorscheme "gruvbox")
(set! gentlewind.freeze_dependencies false)

;; 其他设置
(set! gentlewind.logging "info")
(set! gentlewind.guicolors true)
(set! gentlewind.auto_comment true)
(set! gentlewind.movement_wrap false)
(set! gentlewind.global_statusline true)
(set! gentlewind.clipboard true)
(set! gentlewind.ignorecase true)
(set! gentlewind.smartcase true)
(set! gentlewind.max_columns 120)
(set! gentlewind.disable_numbering false)
(set! gentlewind.relative_num true)
(set! gentlewind.leader_key "<Space>")
(set! gentlewind.check_updates true)

;; Add custom packages
(gentlewind.use_package
  "ellisonleao/gruvbox.nvim"
  "sainnhe/sonokai"
  "EdenEast/nightfox.nvim"
  {:repo "rafcamlet/nvim-luapad"
   :opt true
   :cmd "Luapad"})

;; Add custom keybinds
(gentlewind.use_keybind
  {:<leader>u {:name "+user"
               :s {:cmd "<cmd>Telescope git_status<CR>"
                   :name "Git status"
                   :desc "Git态"}}})

;; Add custom autocommands
(gentlewind.use_autocmd
  ["FileType" "javascript" (fn [] (print "Yuck!"))])

;; Add custom commands
(gentlewind.use_cmd
  ["Test" (fn [] (print "test"))])

;; Override module settings
(when gentlewind.features.whichkey
  (set! gentlewind.features.whichkey.settings.window.height.max 5)
  (table.insert gentlewind.features.whichkey.binds
                 {:<leader>u {:name "+user"
                              :wr {:cmd (fn [] (require :which-key).reset)
                                   :name "Reset whichkey"
                                   :desc "重置键"}}}))

;; Configure Lua module
(when gentlewind.langs.lua
  (set! gentlewind.langs.lua.settings.dev.library.plugins false))

;; Set vim options
(set! vim.opt.colorcolumn "120")
(set! vim.opt.relativenumber true)
(set! vim.opt.wrap false)

;; 加载用户配置模块
((require :user.modules.config.editor).setup)
((require :user.modules.config.ui).setup)
((require :user.modules.config.dev_tools).setup)
((require :user.modules.config.lsp).setup)
((require :user.modules.config.search).setup)

;; 加载 Fennel LSP 增强配置
(vim.api.nvim_create_autocmd "FileType"
  {:pattern "fennel"
   :once true
   :callback (fn []
               ((require :user.modules.config.fennel-lsp).setup)
               ((require :user.modules.config.fennel-neodev).setup)
               ((require :user.modules.config.fennel-fix).setup)
               ((require :user.modules.config.fennel-direct).setup))})

(vim.api.nvim_create_autocmd "User"
  {:pattern "VeryLazy"
   :once true
   :callback (fn []
               ((require :user.modules.config.whichkey-fix).setup))})

;; 加载 treesitter 重复安装修复配置
(vim.api.nvim_create_autocmd "BufReadPre"
  {:pattern "*"
   :once true
   :callback (fn []
               ((require :user.modules.config.treesitter-fix).setup))})

(gentlewind.use_package {:repo "Olical/nfnl" :ft "fennel"})
(gentlewind.use_package "Olical/aniseed")

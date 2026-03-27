;; Example Fennel-based config.lua for Doom Nvim
;; This replaces the traditional Lua config.lua

;; Configure Doom settings
;; 基础配置
(set vim.g.loaded_netrw 1)
(set vim.g.loaded_netrwPlugin 1)
(set vim.opt.colorcolumn "120")
(set vim.g.skip_ts_context_commentstring_module true)
(set! doom.indent 2)
(set! doom.core.treesitter.settings.show_compiler_warning_message false)
(set! doom.core.reloader.settings.reload_on_save true)
(set! doom.colorscheme "gruvbox")
(set! doom.freeze_dependencies false)

;; 其他设置
(set! doom.logging "info")
(set! doom.guicolors true)
(set! doom.auto_comment true)
(set! doom.movement_wrap false)
(set! doom.global_statusline true)
(set! doom.clipboard true)
(set! doom.ignorecase true)
(set! doom.smartcase true)
(set! doom.max_columns 120)
(set! doom.disable_numbering false)
(set! doom.relative_num true)
(set! doom.leader_key "<Space>")
(set! doom.check_updates true)

;; Add custom packages
(doom.use_package
  "ellisonleao/gruvbox.nvim"
  "sainnhe/sonokai"
  "EdenEast/nightfox.nvim"
  {:"rafcamlet/nvim-luapad"
   :opt true
   :cmd "Luapad"})

;; Add custom keybinds
(doom.use_keybind
  {:<leader>u {:name "+user"
               :s {:cmd "<cmd>Telescope git_status<CR>"
                   :name "Git status"
                   :desc "Git态"}}})

;; Add custom autocommands
(doom.use_autocmd
  ["FileType" "javascript" (fn [] (print "Yuck!"))])

;; Add custom commands
(doom.use_cmd
  ["Test" (fn [] (print "test"))])

;; Override module settings
(when doom.features.whichkey
  (set! doom.features.whichkey.settings.window.height.max 5)
  (table.insert doom.features.whichkey.binds
                 {:<leader>u {:name "+user"
                              :wr {:cmd (fn [] (require :which-key).reset)
                                   :name "Reset whichkey"
                                   :desc "重置键"}}}))

;; Configure Lua module
(when doom.langs.lua
  (set! doom.langs.lua.settings.dev.library.plugins false))

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

(doom.use_package {"Olical/nfnl" :ft "fennel"})
(doom.use_package "Olical/aniseed")

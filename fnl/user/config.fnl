;; Example Fennel-based config.lua for Doom Nvim
;; This replaces the traditional Lua config.lua

;; Configure Doom settings
(set! doom.freeze_dependencies false)
(set! doom.logging "info")
(set! doom.indent 2)
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
(set! doom.colorscheme "doom-one")

;; Add custom packages
(doom.use_package
  "sainnhe/sonokai"
  "EdenEast/nightfox.nvim"
  {:"rafcamlet/nvim-luapad"
   :opt true
   :cmd "Luapad"})

;; Add custom keybinds
(doom.use_keybind
  {:<leader>u {:name "+user"
               {:s "<cmd>Telescope git_status<CR>" :name "Git status"}}})

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
                              {:wr (fn [] (require :which-key).reset) :name "Reset whichkey"}}}))

;; Configure Lua module
(when doom.langs.lua
  (set! doom.langs.lua.settings.dev.library.plugins false))

;; Set vim options
(set! vim.opt.colorcolumn "120")
(set! vim.opt.relativenumber true)
(set! vim.opt.wrap false)
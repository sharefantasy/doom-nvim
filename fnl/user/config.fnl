;; Example Fennel-based config.lua for Gentlewind Nvim
;; This replaces the traditional Lua config.lua

;; Configure Gentlewind settings
;; 基础配置
(when vim.api.nvim_create_augroup
  ;; Ensure augroup exists early to avoid E216 when Neovim triggers `:doautoall nvim.lsp.enable FileType`.
  (vim.api.nvim_create_augroup "nvim.lsp.enable" {:clear false}))

(when (and vim.cmd vim.cmd.doautoall)
  ;; Workaround for Neovim 0.12: `vim.lsp.enable()` calls `vim.cmd.doautoall('group event')`.
  ;; In this config, augroup names containing `.` can make `:doautoall` error with E216.
  ;; Implement a compatible doautoall wrapper using `nvim_exec_autocmds`.
  (let [orig vim.cmd.doautoall]
    (set vim.cmd.doautoall
      (fn [arg]
        (if (and (= (type arg) "string") (string.find arg " "))
            (let [parts (vim.split arg " " {:trimempty true})
                  group-name (. parts 1)
                  event-name (. parts 2)
                  group-id (. [(pcall vim.api.nvim_create_augroup group-name {:clear false})] 2)]
              (each [_ buf (ipairs (vim.api.nvim_list_bufs))]
                (pcall vim.api.nvim_exec_autocmds event-name {:group group-id :buffer buf}))
              nil)
            (orig arg))))))

(set vim.g.loaded_netrw 1)
(set vim.g.loaded_netrwPlugin 1)
(set vim.opt.colorcolumn "120")
(set vim.g.skip_ts_context_commentstring_module true)
(set gentlewind.indent 2)
(set gentlewind.modules.core.treesitter.settings.show_compiler_warning_message false)
(set gentlewind.modules.core.reloader.settings.reload_on_save true)
(set gentlewind.colorscheme "gruvbox")
(set gentlewind.freeze_dependencies false)

;; 其他设置
(set gentlewind.logging "info")
(set gentlewind.guicolors true)
(set gentlewind.auto_comment true)
(set gentlewind.movement_wrap false)
(set gentlewind.global_statusline true)
(set gentlewind.clipboard true)
(set gentlewind.ignorecase true)
(set gentlewind.smartcase true)
(set gentlewind.max_columns 120)
(set gentlewind.disable_numbering false)
(set gentlewind.relative_num true)
(set gentlewind.leader_key "<Space>")
(set gentlewind.check_updates false)

;; 添加 gruvbox 颜色主题
(gentlewind.use_package {:repo "ellisonleao/gruvbox.nvim" :priority 1000})



;; 修复 sidekick.nvim 对 copilot 的依赖
(gentlewind.use_package
  {:repo "folke/sidekick.nvim"
   :event "VeryLazy"
   :dependencies ["nvim-lua/plenary.nvim"] ; 移除 copilot.lua
   :config (fn []
             ((. (require :sidekick) :setup)
              {:cli {:tools {:coco {:cmd ["coco"]}}}}))})

;; 接入 agentic.nvim
(gentlewind.use_package
  {:repo "carlos-algms/agentic.nvim"
   :dependencies ["hakonharnes/img-clip.nvim"]
   :opts {:provider "coco"}})

;; img-clip 会覆写 vim.paste；在不可编辑 buffer 触发时会报 E21。
;; 这里加一层保护：不可编辑时直接忽略 paste。
(vim.api.nvim_create_autocmd "User"
  {:pattern "LazyDone"
   :once true
   :callback (fn []
               (local old vim.paste)
               (set vim.paste (fn [lines phase]
                                (if (or (not vim.bo.modifiable) vim.bo.readonly)
                                    (do
                                      (when (or (= phase -1) (= phase 3))
                                        (vim.notify "当前缓冲区不可编辑，已忽略 paste（img-clip）" vim.log.levels.WARN))
                                      nil)
                                    (old lines phase)))))} )


;; Add custom keybinds
(gentlewind.use_keybind
  {:<leader>u {:name "+user"
               :s {:cmd "<cmd>Telescope git_status<CR>"
                   :name "Git status"
                   :desc "Git态"}
               :wr {:cmd (fn [] ((. (require :which-key) :reset)))
                    :name "Reset whichkey"
                    :desc "重置键"}}})

;; Add custom autocommands
(gentlewind.use_autocmd
  ["FileType" "javascript" (fn [] (print "Yuck!"))])

;; Add custom commands
(gentlewind.use_cmd
  ["Test" (fn [] (print "test"))])

;; Override module settings
(when gentlewind.modules.features.whichkey
  (when (not gentlewind.modules.features.whichkey.settings)
    (set gentlewind.modules.features.whichkey.settings {}))
  (when (not gentlewind.modules.features.whichkey.settings.window)
    (set gentlewind.modules.features.whichkey.settings.window {}))
  (when (not gentlewind.modules.features.whichkey.settings.window.height)
    (set gentlewind.modules.features.whichkey.settings.window.height {}))
  (set gentlewind.modules.features.whichkey.settings.window.height.max 5))

;; Configure Lua module
(when gentlewind.modules.langs.lua
  (when (not gentlewind.modules.langs.lua.settings.dev)
    (set gentlewind.modules.langs.lua.settings.dev {}))
  (when (not gentlewind.modules.langs.lua.settings.dev.library)
    (set gentlewind.modules.langs.lua.settings.dev.library {}))
  (set gentlewind.modules.langs.lua.settings.dev.library.plugins false))

;; Set vim options
(set vim.opt.colorcolumn "120")
(set vim.opt.relativenumber true)
(set vim.opt.wrap false)

;; 加载用户配置模块
(fn try_setup [module-name]
  (let [packed [(pcall require module-name)]
        ok (. packed 1)
        mod (. packed 2)]
    (if ok
        (when (. mod :setup)
          ((. mod :setup))))))

(try_setup :user.modules.config.editor)
(try_setup :user.modules.config.ui)
(try_setup :user.modules.config.dev_tools)
(try_setup :user.modules.config.lsp)
(try_setup :user.modules.config.search)

;; 加载 Fennel LSP 增强配置
(vim.api.nvim_create_autocmd "FileType"
  {:pattern "fennel"
   :once true
   :callback (fn []
              (try_setup :user.modules.config.fennel-lsp)
              (try_setup :user.modules.config.fennel-neodev)
              (try_setup :user.modules.config.fennel-fix)
              (try_setup :user.modules.config.fennel-direct))})

(vim.api.nvim_create_autocmd "User"
  {:pattern "VeryLazy"
   :once true
   :callback (fn []
               (try_setup :user.modules.config.whichkey-fix))})

;; 加载 treesitter 重复安装修复配置
(vim.api.nvim_create_autocmd "BufReadPre"
  {:pattern "*"
   :once true
   :callback (fn []
               (try_setup :user.modules.config.treesitter-fix))})

(gentlewind.use_package {:repo "Olical/nfnl" :ft "fennel"})
(gentlewind.use_package "Olical/aniseed")

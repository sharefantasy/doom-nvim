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
(set gentlewind.leader_key " ")
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
   ;; 仅使用本地 `coco/trae-cli` 作为 ACP provider（不会去启动/探测其它 provider 的进程）
   ;; coco 的 ACP server 启动方式：`coco acp serve`
   :opts {:provider "coco"
          :acp_providers {:coco {:name "Coco ACP"
                                :command "coco"
                                :args ["acp" "serve"]
                                :env {}}}

          ;; 让 Agentic 的 UI 更“像聊天”：
          ;; - 分隔线更明显：WinSeparator -> AgenticWinSeparator
          ;; - 输入框更有区分度：Normal -> AgenticInputNormal
          :windows {:chat {:win_opts {:winhighlight "WinSeparator:AgenticWinSeparator"}}
                    :code {:win_opts {:winhighlight "WinSeparator:AgenticWinSeparator"}}
                    :files {:win_opts {:winhighlight "WinSeparator:AgenticWinSeparator"}}
                    :diagnostics {:win_opts {:winhighlight "WinSeparator:AgenticWinSeparator"}}
                    :todos {:win_opts {:winhighlight "WinSeparator:AgenticWinSeparator"}}
                    :input {:height 8
                            :win_opts {:wrap true
                                       :linebreak true
                                       :cursorline true
                                       :winhighlight "Normal:AgenticInputNormal,NormalNC:AgenticInputNormal,SignColumn:AgenticInputNormal,EndOfBuffer:AgenticInputNormal,WinSeparator:AgenticWinSeparator"}}}

          ;; 禁用 UI 内的 provider 切换键（避免误触去选其它 provider）
          ;; 同时把提交改为 Shift-Enter（保留 Ctrl-s 作为终端兼容兜底）
          :keymaps {:widget {:switch_provider []}
                   ;; NOTE: agentic.nvim 的 keymaps 期望：字符串 / 字符串数组 / KeymapEntry
                   ;; KeymapEntry 形如：{ [1] = "<key>", mode = {"i","n","v"} }
                   ;; 这里用 {1 "<key>" :mode [...]} 来确保编译后是正确结构，避免 lhs 变成 table。
                   :prompt {:submit [{1 "<S-CR>" :mode ["i" "n" "v"]}
                                     {1 "<C-s>" :mode ["i" "n" "v"]}]}}}})

;; 让 AgenticChat 的 markdown 更“可读”（富渲染）
;; NOTE: 只对 AgenticChat 启用，避免影响你日常编辑 markdown 文件。
(gentlewind.use_package
  {:repo "MeanderingProgrammer/render-markdown.nvim"
   ;; 不用 ft 懒加载：render-markdown.nvim 在 lazy(ft) 下会默认跳过“当前 buffer” attach，
   ;; 而它的 FileType autocmd 又是在插件加载后才注册，导致第一次打开 AgenticChat 不渲染。
   ;; 用 VeryLazy 提前加载，确保后续 AgenticChat 打开时能正常 attach。
   :event "VeryLazy"
   :dependencies ["nvim-treesitter/nvim-treesitter" "nvim-tree/nvim-web-devicons"]
   ;; IMPORTANT:
   ;; render-markdown.nvim 在 `plugin/render-markdown.lua` 里会调用：
   ;; `require('render-markdown').setup(vim.g.render_markdown_config)`。
   ;; 因此配置必须通过全局变量在插件加载前写入（`init` 阶段）。
   :init (fn []
           ;; 确保 AgenticChat 用 markdown parser（避免依赖 agentic.nvim 自己的 register 时序）
           (pcall vim.treesitter.language.register "markdown" "AgenticChat")

           ;; 让 render-markdown 同时覆盖普通 markdown 和 AgenticChat。
           ;; `RenderMarkdown get` 不会 echo 输出（该命令只调用函数），但渲染会生效。
           (set vim.g.render_markdown_config
             {:enabled true
              :preset "obsidian"
              :file_types ["markdown" "AgenticChat"]
              ;; 在 insert 也保持渲染（Agentic 常驻输入时仍希望 chat 区是渲染态）
              :render_modes ["n" "i" "c" "t"]
              ;; 避免首次加载后遗留高亮状态
              :restart_highlighter true}))})

;; 兜底：AgenticChat 的 filetype 是通过 `nvim_set_option_value(filetype=...)` 写入的，
;; 这条路径不会可靠触发 `FileType` autocmd。
;; 因此改用 BufEnter/BufWinEnter：只要窗口真正进入 AgenticChat buffer，就 attach + render。
(local agentic_render_markdown_group
  (vim.api.nvim_create_augroup "AgenticRenderMarkdown" {:clear true}))

(local ensure-agentic-render-markdown
  (fn [buf]
    (when (and (vim.api.nvim_buf_is_valid buf)
               (= (. (. vim.bo buf) :filetype) "AgenticChat"))
      ;; 确保 markdown parser / TS 高亮
      (pcall vim.treesitter.start buf "markdown")

      ;; 确保 render-markdown 已加载
      (let [(ok-lazy lazy) (pcall require :lazy)]
        (when ok-lazy
          (pcall (. lazy :load) {:plugins ["render-markdown.nvim"]})))

      (pcall
        (fn []
          (local mgr (require :render-markdown.core.manager))
          ((. mgr :attach) buf)

          ;; 对所有显示该 buffer 的窗口强制渲染一次
          (local wins (vim.fn.win_findbuf buf))
          (when (and wins (> (# wins) 0))
            (local ui (require :render-markdown.core.ui))
            (each [_ win (ipairs wins)]
              (pcall vim.api.nvim_set_option_value "conceallevel" 2 {:scope "local" :win win})
              (pcall vim.api.nvim_set_option_value "concealcursor" "nc" {:scope "local" :win win})
              ((. ui :update) buf win "AgenticChat" true)))))))
    )

(vim.api.nvim_create_autocmd ["BufWinEnter" "BufEnter" "WinEnter"]
  {:group agentic_render_markdown_group
   :pattern "*"
   :callback (fn [args]
               (local buf (or (and args args.buf) (vim.api.nvim_get_current_buf)))
               (ensure-agentic-render-markdown buf))})

;; gruvbox + Tree-sitter 的 Markdown 语义高亮默认较“灰”，这里做一次仅针对 markdown 的覆写。
(vim.api.nvim_create_autocmd "ColorScheme"
  {:pattern "gruvbox"
   :callback (fn []
               (local sethl vim.api.nvim_set_hl)
               (local gethl vim.api.nvim_get_hl)

               ;; focus.nvim 的 winhighlight 会把 Normal 映射到 FocusedWindow；默认它竟然 link 到 VertSplit，导致正文发灰。
               ;; 这里把 FocusedWindow 修正回 Normal，并把 UnfocusedWindow 映射到 NormalNC。
               (sethl 0 "FocusedWindow" {:link "Normal"})
               (sethl 0 "UnfocusedWindow" {:link "NormalNC"})

               (fn fg-of [name fallback]
                 (let [(ok hl) (pcall gethl 0 {:name name :link true})]
                   (if (and ok hl (. hl :fg)) (. hl :fg) fallback)))

               (local fg-yellow (fg-of "GruvboxYellow" nil))
               (local fg-orange (fg-of "GruvboxOrange" nil))
               (local fg-aqua (fg-of "GruvboxAqua" nil))
               (local fg-blue (fg-of "GruvboxBlue" nil))
               (local fg-green (fg-of "GruvboxGreen" nil))

               ;; list markers
               (sethl 0 "@markup.list.markdown" {:fg fg-orange})

               ;; emphasis
               (sethl 0 "@markup.strong.markdown_inline" {:link "GruvboxYellowBold"})
               (sethl 0 "@markup.italic.markdown_inline" {:fg fg-aqua :italic true})

               ;; code span / code block
               (sethl 0 "@markup.raw.markdown_inline" {:fg fg-green})
               (sethl 0 "@markup.raw.block.markdown" {:fg fg-green})

               ;; headings
               (sethl 0 "@markup.heading.1.markdown" {:link "GruvboxYellowBold"})
               (sethl 0 "@markup.heading.2.markdown" {:link "GruvboxOrangeBold"})
               (sethl 0 "@markup.heading.3.markdown" {:link "GruvboxAquaBold"})

               ;; links
               (sethl 0 "@markup.link.label.markdown_inline" {:fg fg-blue :underline true})
               (sethl 0 "@markup.link.url.markdown_inline" {:fg fg-aqua :underline true})

               ;; 兼容部分主题未定义的组
               (when fg-yellow
                 (sethl 0 "@markup.heading.markdown" {:fg fg-yellow :bold true})))})

;; Agentic UI 覆写：
;; - 输入框底色：用 Pmenu（更容易区分输入区）
;; - 分隔线颜色：尽量取 GruvboxBlue 的前景色
(vim.api.nvim_create_autocmd "ColorScheme"
  {:pattern "gruvbox"
   :callback (fn []
               (local sethl vim.api.nvim_set_hl)
               (local gethl vim.api.nvim_get_hl)

               (fn fg-of [name fallback]
                 (let [(ok hl) (pcall gethl 0 {:name name :link true})]
                   (if (and ok hl (. hl :fg)) (. hl :fg) fallback)))

               ;; 输入区底色
               (sethl 0 "AgenticInputNormal" {:link "Pmenu"})

               ;; 分隔线
               (let [fg-blue (fg-of "GruvboxBlue" nil)]
                 (if fg-blue
                     (sethl 0 "AgenticWinSeparator" {:fg fg-blue :bold true})
                     (sethl 0 "AgenticWinSeparator" {:link "WinSeparator"}))))})

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

;; which-key overlap: gc vs gcc（注释插件的 operator + line）。如果你更想要“无 warning”，这里保留 gcc，移除 n 模式 gc。
(vim.api.nvim_create_autocmd "User"
  {:pattern "LazyDone"
   :once true
   :callback (fn []
               (pcall (fn [] (vim.api.nvim_del_keymap "n" "gc"))))})


;; Add custom keybinds
(gentlewind.use_keybind
  {:<leader>u {:name "+user"
               :wr {:cmd (fn [] ((. (require :which-key) :reset)))
                    :name "Reset whichkey"
                    :desc "重置键"}}})

;; Spacemacs 风格：Git / Debug / Tools(Hurl) 入口
(gentlewind.use_keybind
  {:<leader>g {:name "+git"
               :g {:cmd (fn [] ((. (require :user.modules.config.dev_tools) :activate_git_hydra)))
                   :desc "Git 菜单"}
               :c {:name "+conflict"
                   :c {:cmd (fn [] ((. (require :user.modules.config.dev_tools) :activate_conflict_hydra)))
                       :desc "Conflict 菜单"}
                   :q {:cmd (fn [] ((. (require :user.modules.config.dev_tools) :conflict_quickfix)))
                       :desc "冲突列表"}
                   :n {:cmd (fn [] ((. (require :user.modules.config.dev_tools) :conflict_next)))
                       :desc "下一个冲突"}
                   :p {:cmd (fn [] ((. (require :user.modules.config.dev_tools) :conflict_prev)))
                       :desc "上一个冲突"}
                   :v {:cmd (fn [] ((. (require :user.modules.config.dev_tools) :toggle_conflict_view)))
                       :desc "切换视图"}}}
   :<leader>d {:cmd (fn [] ((. (require :user.modules.config.dev_tools) :toggle_debug_hydra)))
               :desc "Debug 菜单"}
   :<leader>a {:cmd (fn [] ((. (require :user.modules.config.dev_tools) :activate_agentic_hydra)))
               :desc "AI 菜单"}
   :<leader>t {:name "+tools"
               :h {:cmd (fn [] ((. (require :user.modules.config.dev_tools) :activate_hurl_hydra)))
                   :desc "Hurl 菜单"}}})

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

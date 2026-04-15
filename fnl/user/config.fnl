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
(set vim.g.maplocalleader ",")
(set gentlewind.check_updates false)

;; 统一 Neovim & Zellij pane/tab 导航的开关（true 启用，false 关闭所有 zellij-nav 键位）
(set vim.g.gentlewind_zellij_nav_enabled true)

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

;; =============================
;; Keymaps: global + minor-mode
;; =============================

(fn ensure-plugin [name]
  (let [packed [(pcall require :lazy)]
        ok (. packed 1)
        lazy (. packed 2)]
    (when ok
      (pcall (fn [] ((. lazy :load) {:plugins [name]}))))))

(fn project-root [markers]
  (let [packed [(pcall (fn [] (vim.fs.root 0 markers)))]
        ok (. packed 1)
        root (. packed 2)]
    (if (and ok root (not= root "")) root (vim.fn.getcwd))))

(fn run-in-term [cmd cwd]
  (let [prev (vim.fn.getcwd)]
    (when (and cwd (not= cwd ""))
      (pcall vim.api.nvim_set_current_dir cwd))
    (pcall (fn [] (vim.cmd (.. "botright split | terminal " cmd))))
    (pcall vim.api.nvim_set_current_dir prev)
    (pcall vim.cmd "startinsert")))

;; 统一 pane/tab 导航键位：<C-h/j/k/l>
;; - 在 Neovim 内先走 window 移动
;; - 到达边缘时由 zellij-nav.nvim 切换 Zellij pane/tab
(vim.api.nvim_create_autocmd
  "User"
  {:pattern "LazyDone"
   :once true
   :callback
   (fn []
     (when (or (not vim.g.gentlewind_zellij_nav_enabled)
               (= vim.g.gentlewind_zellij_nav_enabled true))
       (let [map (fn [lhs cmd desc]
                   (vim.keymap.set
                     "n"
                     lhs
                     (fn [] (pcall vim.cmd cmd))
                     {:silent true :noremap true :desc desc}))]
         (map "<C-h>" "ZellijNavigateLeftTab" "Pane: Left / Prev tab")
         (map "<C-j>" "ZellijNavigateDown" "Pane: Down")
         (map "<C-k>" "ZellijNavigateUp" "Pane: Up")
        (map "<C-l>" "ZellijNavigateRightTab" "Pane: Right / Next tab"))))})

;; 全局高频：Lists(Trouble) / Symbols(Aerial) / Sessions(Persistence)
(vim.api.nvim_create_autocmd "User"
  {:pattern "LazyDone"
   :once true
   :callback (fn []
               ;; Lists: Trouble
               (vim.keymap.set "n" "<leader>l" (fn [] (pcall vim.cmd "Trouble diagnostics toggle"))
                             {:silent true :noremap true :desc "Lists: Diagnostics (Trouble)"})
               (vim.keymap.set "n" "<leader>ld" (fn [] (pcall vim.cmd "Trouble diagnostics toggle"))
                             {:silent true :noremap true :desc "Lists: Diagnostics (Trouble)"})
               (vim.keymap.set "n" "<leader>lq" (fn [] (pcall vim.cmd "Trouble qflist toggle"))
                             {:silent true :noremap true :desc "Lists: Quickfix (Trouble)"})
               (vim.keymap.set "n" "<leader>ll" (fn [] (pcall vim.cmd "Trouble loclist toggle"))
                             {:silent true :noremap true :desc "Lists: Loclist (Trouble)"})

               ;; Symbols: Aerial
               (vim.keymap.set "n" "<leader>s" (fn [] (pcall vim.cmd "AerialToggle"))
                             {:silent true :noremap true :desc "Symbols: Aerial"})

               ;; Sessions: Persistence（放到 <leader>p 下，但避免与现有 picker 冲突）
               (vim.keymap.set "n" "<leader>pR"
                             (fn []
                               (ensure-plugin "persistence.nvim")
                               (let [packed [(pcall require :persistence)]]
                                 (when (. packed 1)
                                   ((. (. packed 2) :load)))))
                             {:silent true :noremap true :desc "Session: Restore"})
               (vim.keymap.set "n" "<leader>pL"
                             (fn []
                               (ensure-plugin "persistence.nvim")
                               (let [packed [(pcall require :persistence)]]
                                 (when (. packed 1)
                                   ((. (. packed 2) :load) {:last true}))))
                             {:silent true :noremap true :desc "Session: Restore last"})
               (vim.keymap.set "n" "<leader>pS"
                             (fn []
                               (ensure-plugin "persistence.nvim")
                               (let [packed [(pcall require :persistence)]]
                                 (when (. packed 1)
                                   ((. (. packed 2) :stop)))))
                             {:silent true :noremap true :desc "Session: Stop"})
               )})

;; 语言 minor-mode（localleader=","，buffer-local）
(vim.api.nvim_create_autocmd "FileType"
  {:pattern ["http" "rest"]
   :callback (fn [args]
               (local bufnr args.buf)
               ;; Kulala 的 request buffer 如果没有高亮，优先确保 TS parser（http）可用
               ;; 这里注册 ts grammar，让 core/treesitter 在 GentlewindStarted 时自动补齐。
               (pcall (fn []
                        (when (and gentlewind gentlewind.register_ts_grammar)
                          (gentlewind.register_ts_grammar "http"))))

               ;; 兜底：确保当前 buffer 启用 Tree-sitter 高亮。
               ;; 现状：能拿到 parser（lang=kulala_http），但未自动启动 highlighter。
               ;; 这里不显式传 lang，让 Neovim 用 filetype 自行映射到 kulala_http。
               (vim.schedule
                 (fn []
                   (pcall vim.treesitter.start bufnr)))
               (local k
                 (fn [f]
                   (ensure-plugin "kulala.nvim")
                   (let [packed [(pcall require :kulala)]
                         ok (. packed 1)
                         kulala (. packed 2)]
                     (when ok
                       (pcall (fn [] (f kulala)))))))

               ;; 与 hurl minor-mode 保持一致的 localleader 入口
               (vim.keymap.set "n" ",h" (fn [] ((. (require :gentlewind.modules.config.dev_tools) :activate_http_hydra)))
                             {:buffer bufnr :silent true :noremap true :desc "HTTP: Hydra"})
               (vim.keymap.set "n" ",r" (fn [] (k (fn [m] ((. m :run)))))
                             {:buffer bufnr :silent true :noremap true :desc "HTTP: Run"})
               (vim.keymap.set "n" ",a" (fn [] (k (fn [m] ((. m :run_all)))))
                             {:buffer bufnr :silent true :noremap true :desc "HTTP: Run all"})
               (vim.keymap.set "n" ",e" (fn [] (k (fn [m] ((. m :search)))))
                             {:buffer bufnr :silent true :noremap true :desc "HTTP: Pick request"})
               (vim.keymap.set "n" ",o" (fn [] (k (fn [m] ((. m :open)))))
                             {:buffer bufnr :silent true :noremap true :desc "HTTP: Open UI"})
               (vim.keymap.set "n" ",b" (fn [] (k (fn [m] ((. m :scratchpad)))))
                             {:buffer bufnr :silent true :noremap true :desc "HTTP: Scratchpad"})
               (vim.keymap.set "n" ",c" (fn [] (k (fn [m] ((. m :copy)))))
                             {:buffer bufnr :silent true :noremap true :desc "HTTP: Copy as cURL"})
               (vim.keymap.set "n" ",v" (fn [] (k (fn [m] ((. m :toggle_view)))))
                             {:buffer bufnr :silent true :noremap true :desc "HTTP: Toggle view"})
               (vim.keymap.set "n" ",E" (fn [] (k (fn [m] ((. m :set_selected_env)))))
                             {:buffer bufnr :silent true :noremap true :desc "HTTP: Select env"})

               ;; History（方案 A）：打开 kulala 的 jsonl 历史文件
               (vim.keymap.set "n" ",H" (fn []
                                           ((. (require :gentlewind.modules.config.dev_tools) :kulala_open_history)))
                             {:buffer bufnr :silent true :noremap true :desc "HTTP: History"})

               ;; 验证项（先占位）：Kulala 响应 buffer 的 filetype 应能被识别为 json/html/xml 等，触发 treesitter 高亮。
               ;; TODO: 接入后如果发现响应窗口 ft 不正确，再在这里加 BufEnter/BufWinEnter 针对 kulala 响应窗的兜底。
               )})

;; Kulala 响应窗口：强制 markdown（解决 ft=scratch 导致无高亮的问题）
;; - 仅针对 kulala 的 UI buffer（kulala://ui）
;; - 仅在 filetype= scratch 时兜底，避免覆盖 kulala 自己的 *.kulala_ui filetype
(vim.api.nvim_create_autocmd ["BufEnter" "BufWinEnter"]
  {:callback (fn []
               (let [name (vim.api.nvim_buf_get_name 0)
                     ft vim.bo.filetype]
                 (when (and (= name "kulala://ui") (= ft "scratch"))
                   (pcall vim.cmd "setlocal filetype=markdown"))))})

(vim.api.nvim_create_autocmd "FileType"
  {:pattern "hurl"
   :callback (fn [args]
               (local bufnr args.buf)
               (local cmd
                 (fn [ex]
                   (ensure-plugin "hurl.nvim")
                   (pcall vim.cmd ex)))

               (local scratch
                 (fn []
                   (vim.cmd "enew")
                   (set vim.bo.filetype "hurl")
                   (pcall vim.api.nvim_buf_set_lines 0 0 -1 false ["GET http://localhost:8080" "" "# @name example" ""])) )

               (vim.keymap.set "n" ",h" (fn [] ((. (require :gentlewind.modules.config.dev_tools) :activate_http_hydra)))
                             {:buffer bufnr :silent true :noremap true :desc "Hurl: Hydra"})
               (vim.keymap.set "n" ",r" (fn [] (cmd "HurlRunner"))
                             {:buffer bufnr :silent true :noremap true :desc "Hurl: Run"})
               (vim.keymap.set "v" ",r" (fn [] (cmd "'<,'>HurlRunner"))
                             {:buffer bufnr :silent true :noremap true :desc "Hurl: Run selection"})
               (vim.keymap.set "n" ",e" (fn [] (cmd "HurlRunnerToEntry"))
                             {:buffer bufnr :silent true :noremap true :desc "Hurl: Run entry"})
               (vim.keymap.set "n" ",m" (fn [] (cmd "HurlToggleMode"))
                             {:buffer bufnr :silent true :noremap true :desc "Hurl: Toggle mode"})
               (vim.keymap.set "n" ",v" (fn [] (cmd "HurlVerbose"))
                             {:buffer bufnr :silent true :noremap true :desc "Hurl: Verbose"})
               (vim.keymap.set "n" ",b" scratch
                             {:buffer bufnr :silent true :noremap true :desc "Hurl: Scratch"})
               )})

;; SQL/DB minor-mode（localleader=","，buffer-local）
(vim.api.nvim_create_autocmd "FileType"
  {:pattern ["sql" "mysql" "plsql"]
   :callback (fn [args]
               (local bufnr args.buf)
               (vim.keymap.set "n" ",o" (fn []
                                           (ensure-plugin "vim-dadbod-ui")
                                           (pcall vim.cmd "DBUIToggle"))
                             {:buffer bufnr :silent true :noremap true :desc "DB: Toggle UI"})
               (vim.keymap.set "n" ",a" (fn []
                                           (ensure-plugin "vim-dadbod-ui")
                                           (pcall vim.cmd "DBUIAddConnection"))
                             {:buffer bufnr :silent true :noremap true :desc "DB: Add connection"})
               (vim.keymap.set "n" ",f" (fn []
                                           (ensure-plugin "vim-dadbod-ui")
                                           (pcall vim.cmd "DBUIFindBuffer"))
                             {:buffer bufnr :silent true :noremap true :desc "DB: Find buffer"})

               ;; 执行：当前行 / 选区（dadbod 的 :DB 支持范围）
               (vim.keymap.set "n" ",r" (fn []
                                           (ensure-plugin "vim-dadbod")
                                           (pcall vim.cmd ".DB"))
                             {:buffer bufnr :silent true :noremap true :desc "DB: Run line"})
               (vim.keymap.set "v" ",r" (fn []
                                           (ensure-plugin "vim-dadbod")
                                           (pcall vim.cmd "'<,'>DB"))
                             {:buffer bufnr :silent true :noremap true :desc "DB: Run selection"})

               ;; dadbod completion：如果你用 nvim-cmp，这里只兜底 omnifunc
               (pcall (fn [] (set vim.bo.omnifunc "vim_dadbod_completion#omni")))
               )})

;; CSV/TSV minor-mode（localleader=","，buffer-local）
(vim.api.nvim_create_autocmd "FileType"
  {:pattern ["csv" "tsv"]
   :callback (fn [args]
               (local bufnr args.buf)
               (vim.keymap.set "n" ",v" (fn []
                                           (ensure-plugin "csvview.nvim")
                                           (pcall vim.cmd "CsvViewToggle"))
                             {:buffer bufnr :silent true :noremap true :desc "CSV: Toggle view"})
               (vim.keymap.set "n" ",i" (fn []
                                           (ensure-plugin "csvview.nvim")
                                           (pcall vim.cmd "CsvViewInfo"))
                             {:buffer bufnr :silent true :noremap true :desc "CSV: Info"})
               )})

;; JSON/YAML minor-mode（localleader=","，buffer-local）
(vim.api.nvim_create_autocmd "FileType"
  {:pattern ["json" "jsonc" "yaml" "yml"]
   :callback (fn [args]
               (local bufnr args.buf)
               (vim.keymap.set "n" ",j" (fn []
                                           (ensure-plugin "jq-playground.nvim")
                                           (pcall vim.cmd "JqPlayground"))
                             {:buffer bufnr :silent true :noremap true :desc "JQ: Playground"})
               )})

(vim.api.nvim_create_autocmd "FileType"
  {:pattern "markdown"
   :callback (fn [args]
               (local bufnr args.buf)
               (vim.keymap.set "n" ",p" (fn [] (pcall vim.cmd "MarkdownPreviewToggle"))
                             {:buffer bufnr :silent true :noremap true :desc "Markdown: Preview"}))})

(vim.api.nvim_create_autocmd "FileType"
  {:pattern "python"
   :callback (fn [args]
               (local bufnr args.buf)
               (local root (project-root ["pyproject.toml" "setup.py" "requirements.txt" ".git"]))
               (vim.keymap.set "n" ",t" (fn [] (run-in-term "pytest -q" root))
                             {:buffer bufnr :silent true :noremap true :desc "Python: Test (pytest)"})
               (vim.keymap.set "n" ",T" (fn [] ((. (require :gentlewind.modules.config.dev_tools) :activate_neotest_hydra)))
                             {:buffer bufnr :silent true :noremap true :desc "Test: Neotest Hydra"})
               (vim.keymap.set "n" ",v" (fn []
                                           (ensure-plugin "venv-selector.nvim")
                                           (pcall vim.cmd "VenvSelect"))
                             {:buffer bufnr :silent true :noremap true :desc "Python: Select venv"})
               (vim.keymap.set "n" ",r"
                             (fn []
                               (local file (vim.fn.shellescape (vim.fn.expand "%:p")))
                               (run-in-term (.. "python3 " file) root))
                             {:buffer bufnr :silent true :noremap true :desc "Python: Run file"})
               )})

(vim.api.nvim_create_autocmd "FileType"
  {:pattern "go"
   :callback (fn [args]
               (local bufnr args.buf)
               (local root (project-root ["go.mod" ".git"]))
               (vim.keymap.set "n" ",t" (fn [] (run-in-term "go test ./..." root))
                             {:buffer bufnr :silent true :noremap true :desc "Go: Test ./..."})
               (vim.keymap.set "n" ",T" (fn [] ((. (require :gentlewind.modules.config.dev_tools) :activate_neotest_hydra)))
                             {:buffer bufnr :silent true :noremap true :desc "Test: Neotest Hydra"})
               (vim.keymap.set "n" ",a" (fn []
                                           (ensure-plugin "go.nvim")
                                           (pcall vim.cmd "GoAltV"))
                             {:buffer bufnr :silent true :noremap true :desc "Go: Alt (vsplit)"})
               (vim.keymap.set "n" ",i" (fn []
                                           (ensure-plugin "go.nvim")
                                           (pcall vim.cmd "GoInstallBinaries"))
                             {:buffer bufnr :silent true :noremap true :desc "Go: Install tools"})
               (vim.keymap.set "n" ",r"
                             (fn []
                               (local file (vim.fn.shellescape (vim.fn.expand "%:p")))
                               (run-in-term (.. "go run " file) root))
                             {:buffer bufnr :silent true :noremap true :desc "Go: Run file"})
               (vim.keymap.set "n" ",m" (fn [] (run-in-term "go mod tidy" root))
                             {:buffer bufnr :silent true :noremap true :desc "Go: Mod tidy"})
               )})

;; Debug minor-mode（localleader=","，buffer-local）
;; - 只在可调试语言 buffer 启用
;; - 按需加载 nvim-dap，避免启动期开销
(vim.api.nvim_create_autocmd "FileType"
  {:pattern ["python" "go" "lua" "rust" "javascript" "typescript"]
   :callback (fn [args]
               (local bufnr args.buf)
               (local dap-call
                 (fn [f]
                   (ensure-plugin "nvim-dap")
                   (let [packed [(pcall require :dap)]]
                     (when (. packed 1)
                       (pcall (fn [] (f (. packed 2))))))))

               (vim.keymap.set "n" ",d" (fn [] (dap-call (fn [dap] (dap.continue))))
                             {:buffer bufnr :silent true :noremap true :desc "Debug: Continue"})
               (vim.keymap.set "n" ",b" (fn [] (dap-call (fn [dap] (dap.toggle_breakpoint))))
                             {:buffer bufnr :silent true :noremap true :desc "Debug: Toggle breakpoint"})
               (vim.keymap.set "n" ",n" (fn [] (dap-call (fn [dap] (dap.step_over))))
                             {:buffer bufnr :silent true :noremap true :desc "Debug: Step over"})
               (vim.keymap.set "n" ",i" (fn [] (dap-call (fn [dap] (dap.step_into))))
                             {:buffer bufnr :silent true :noremap true :desc "Debug: Step into"})
               (vim.keymap.set "n" ",o" (fn [] (dap-call (fn [dap] (dap.step_out))))
                             {:buffer bufnr :silent true :noremap true :desc "Debug: Step out"})
               (vim.keymap.set "n" ",c" (fn [] (dap-call (fn [dap] (dap.run_to_cursor))))
                             {:buffer bufnr :silent true :noremap true :desc "Debug: Run to cursor"})
               (vim.keymap.set "n" ",q"
                             (fn []
                               (dap-call
                                 (fn [dap]
                                   (pcall (fn [] (dap.terminate)))
                                   (pcall (fn [] (dap.close))))))
                             {:buffer bufnr :silent true :noremap true :desc "Debug: Stop"})
               )})


;; Add custom keybinds
(gentlewind.use_keybind
  {:<leader>u {:name "+user"
               :wr {:cmd (fn [] ((. (require :which-key) :reset)))
                    :name "Reset whichkey"
                    :desc "重置键"}}})

;; Spacemacs 风格：Git / Debug / Tools(Hurl) 入口
(gentlewind.use_keybind
  {:<leader>g {:name "+git"
               :g {:cmd (fn [] ((. (require :gentlewind.modules.config.dev_tools) :activate_git_hydra)))
                   :desc "Git 菜单"}
               :c {:name "+conflict"
                   :c {:cmd (fn [] ((. (require :gentlewind.modules.config.dev_tools) :activate_conflict_hydra)))
                       :desc "Conflict 菜单"}
                   :q {:cmd (fn [] ((. (require :gentlewind.modules.config.dev_tools) :conflict_quickfix)))
                       :desc "冲突列表"}
                   :n {:cmd (fn [] ((. (require :gentlewind.modules.config.dev_tools) :conflict_next)))
                       :desc "下一个冲突"}
                   :p {:cmd (fn [] ((. (require :gentlewind.modules.config.dev_tools) :conflict_prev)))
                       :desc "上一个冲突"}
                   :v {:cmd (fn [] ((. (require :gentlewind.modules.config.dev_tools) :toggle_conflict_view)))
                       :desc "切换视图"}}}
   :<leader>d {:cmd (fn [] ((. (require :gentlewind.modules.config.dev_tools) :toggle_debug_hydra)))
               :desc "Debug 菜单"}
   :<leader>a {:cmd (fn [] ((. (require :gentlewind.modules.config.dev_tools) :activate_agentic_hydra)))
               :desc "AI 菜单"}
  :<leader>o {:name "+open"
               :d {:cmd (fn []
                         (ensure-plugin "vim-dadbod-ui")
                         (pcall vim.cmd "DBUIToggle"))
                   :desc "DB: Toggle UI"}
               :D {:cmd (fn []
                         (ensure-plugin "vim-dadbod-ui")
                         (pcall vim.cmd "DBUI"))
                   :desc "DB: Open UI"}
               :a {:cmd (fn []
                         (ensure-plugin "vim-dadbod-ui")
                         (pcall vim.cmd "DBUIAddConnection"))
                   :desc "DB: Add connection"}
               :f {:cmd (fn []
                         (ensure-plugin "vim-dadbod-ui")
                         (pcall vim.cmd "DBUIFindBuffer"))
                   :desc "DB: Find buffer"}
               :v {:cmd (fn []
                         (ensure-plugin "venv-selector.nvim")
                         (pcall vim.cmd "VenvSelect"))
                   :desc "Python: Select venv"}
               :j {:cmd (fn []
                         (ensure-plugin "jq-playground.nvim")
                         (pcall vim.cmd "JqPlayground"))
                   :desc "JQ: Playground"}}
  :<leader>t {:name "+tools"
              :t {:cmd (fn [] ((. (require :gentlewind.modules.config.dev_tools) :activate_neotest_hydra)))
                  :desc "Test 菜单"}
              :h {:cmd (fn [] ((. (require :gentlewind.modules.config.dev_tools) :activate_http_hydra)))
                  :desc "HTTP/Hurl 菜单"}}})

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

;; 将 Mason 的 bin 加入 PATH，便于 jq-playground / venv-selector 等插件直接调用 Mason 安装的工具
(let [mason-bin (.. (vim.fn.stdpath :data) "/mason/bin")
      path (or vim.env.PATH "")]
  (when (and (not= mason-bin "")
             (not (string.find path mason-bin 1 true)))
    (set vim.env.PATH (.. mason-bin ":" path))))

;; kulala_http treesitter 高亮补强：把自定义 capture 映射到更“gruvbox”的颜色层次
;; NOTE: 只 link 未定义的 group，不覆盖主题本身。
(let [link-default
      (fn [from to]
        (pcall vim.api.nvim_set_hl 0 from {:link to :default true}))
      apply
      (fn []
        ;; query params / form params
        (link-default "@query_param.name.kulala_http" "Identifier")
        (link-default "@query_param.value.kulala_http" "String")
        (link-default "@form_param_name.kulala_http" "Identifier")
        (link-default "@form_param_value.kulala_http" "String")
        ;; paths / redirects
        (link-default "@external_body_path.kulala_http" "Directory")
        (link-default "@redirect_path.kulala_http" "String")
        ;; status
        (link-default "@status_code.kulala_http" "Number")
        (link-default "@status_text.kulala_http" "String")
        ;; scripts
        (link-default "@number.special.path.kulala_http" "Special")
        ;; punctuation
        (link-default "@punctuation.special.kulala_http" "Delimiter"))]
  (vim.api.nvim_create_autocmd "ColorScheme" {:callback apply})
  (apply))

;; 加载用户配置模块
(fn try_setup [module-name]
  (let [packed [(pcall require module-name)]
        ok (. packed 1)
        mod (. packed 2)]
    (if ok
        (when (. mod :setup)
          ((. mod :setup))))))

(try_setup :gentlewind.modules.config.editor)
(try_setup :gentlewind.modules.config.ui)
(try_setup :gentlewind.modules.config.dev_tools)
(try_setup :gentlewind.modules.config.lsp)
(try_setup :gentlewind.modules.config.search)

;; 加载 Fennel LSP 增强配置
(vim.api.nvim_create_autocmd "FileType"
  {:pattern "fennel"
   :once true
   :callback (fn []
              (try_setup :gentlewind.modules.config.fennel-lsp)
              (try_setup :gentlewind.modules.config.fennel-neodev)
              (try_setup :gentlewind.modules.config.fennel-fix)
              (try_setup :gentlewind.modules.config.fennel-direct))})

(vim.api.nvim_create_autocmd "User"
  {:pattern "VeryLazy"
   :once true
   :callback (fn []
               (try_setup :gentlewind.modules.config.whichkey-fix))})

;; 加载 treesitter 重复安装修复配置
(vim.api.nvim_create_autocmd "BufReadPre"
  {:pattern "*"
   :once true
   :callback (fn []
               (try_setup :gentlewind.modules.config.treesitter-fix))})

(gentlewind.use_package {:repo "Olical/nfnl" :ft "fennel"})
(gentlewind.use_package "Olical/aniseed")

;; 加载额外配置（如：nvim.sh 自动写入的插件列表）
(pcall require :user.extra)

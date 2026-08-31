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



;; Sidekick 统一使用 TraeX CLI，避免与旧版 Coco 双轨运行
(gentlewind.use_package
  {:repo "folke/sidekick.nvim"
   :event "VeryLazy"
   :dependencies ["nvim-lua/plenary.nvim"]
   :config (fn []
             ((. (require :sidekick) :setup)
              {:cli {:tools {:traex {:cmd ["traex"]}}}}))})

;; 接入 agentic.nvim
(gentlewind.use_package
  {:repo "carlos-algms/agentic.nvim"
   :dependencies ["hakonharnes/img-clip.nvim"]
   ;; 仅使用新版 TraeX 作为 ACP provider；它会读取 ~/.trae/traecli.toml 中的 Skills/MCP 配置。
   :opts {:provider "traex"
          :acp_providers {:traex {:name "TRAE CLI"
                                  :command "traex"
                                  :args ["acp" "serve"]
                                  :env {}}}

          ;; 让 Agentic 的 UI 更“像聊天”：
          ;; - 默认放在底部，给右侧 Lean Infoview / 其他侧栏留空间
          ;; - 分隔线更明显：WinSeparator -> AgenticWinSeparator
          ;; - 输入框更有区分度：Normal -> AgenticInputNormal
          :windows {:position "bottom"
                    :width "42%"
                    :height "32%"
                    :stack_width_ratio 0.35
                    :chat {:win_opts {:winhighlight "WinSeparator:AgenticWinSeparator"}}
                    :code {:max_height 6
                           :win_opts {:winhighlight "WinSeparator:AgenticWinSeparator"}}
                    :files {:max_height 5
                            :win_opts {:winhighlight "WinSeparator:AgenticWinSeparator"}}
                    :diagnostics {:max_height 6
                                  :win_opts {:winhighlight "WinSeparator:AgenticWinSeparator"}}
                    :todos {:display false
                            :max_height 6
                            :win_opts {:winhighlight "WinSeparator:AgenticWinSeparator"}}
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

;; 让 Markdown / AgenticChat 的 markdown 更“可读”（富渲染）
;; 普通 markdown 与 AgenticChat 都启用 render-markdown；
;; AgenticChat 仍保留下面的特殊 attach 兜底，避免其 filetype 写入时序导致首次不渲染。
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
      ;; 先安装缺失插件（避免第一次触发 keymap 时无反应）
      (pcall (fn [] ((. lazy :install) {:plugins [name] :wait true :show false})))
      ;; 再 load 让插件立刻可用
      (pcall (fn [] ((. lazy :load) {:plugins [name]}))))))

(fn project-root [markers]
  (let [packed [(pcall (fn [] (vim.fs.root 0 markers)))]
        ok (. packed 1)
        root (. packed 2)]
    (if (and ok root (not= root "")) root (vim.fn.getcwd))))

;; =============================
;; Obsidian (方案A + nfnl 项目专用 vault)
;; =============================
;; 规则：
;; 1) 若用户已手动设置 `vim.g.obsidian_workspaces`，不覆盖
;; 2) 若项目根存在 `.nfnl.fnl`/`.nfnl.lua` 且包含 `obsidian_vault`，则使用该 vault
;; 3) 否则若设置了 `vim.g.obsidian_default_vault`，则作为默认 vault

(fn _read-all [path]
  (let [packed [(pcall vim.fn.readfile path)]
        ok (. packed 1)
        lines (. packed 2)]
    (if ok (table.concat lines "\n") "")))

(fn _extract-vault [content]
  (when (and content (not= content ""))
    ;; 支持：
    ;; - Fennel: :obsidian_vault "/path" 或 :obsidian-vault "/path"
    ;; - Lua: obsidian_vault = "/path" 或 obsidian-vault = "/path"（容错）
    (or
      (string.match content ":obsidian[_%-]vault%s+\"([^\"]+)\"")
      (string.match content ":obsidian[_%-]vault%s+'([^']+)'")
      (string.match content "obsidian[_%-]vault%s*=%s*\"([^\"]+)\"")
      (string.match content "obsidian[_%-]vault%s*=%s*'([^']+)'")
      (string.match content "OBSIDIAN[_%-]VAULT%s*=%s*\"([^\"]+)\"")
      (string.match content "OBSIDIAN[_%-]VAULT%s*=%s*'([^']+)'")
      nil)))

(fn obsidian-project-vault []
  (let [root (project-root [".nfnl.fnl" ".nfnl.lua" ".git"])
        cfg1 (vim.fs.joinpath root ".nfnl.fnl")
        cfg2 (vim.fs.joinpath root ".nfnl.lua")
        has1 (= (vim.fn.filereadable cfg1) 1)
        has2 (= (vim.fn.filereadable cfg2) 1)
        content (if has1 (_read-all cfg1) (if has2 (_read-all cfg2) ""))
        vault (_extract-vault content)]
    (if (and vault (not= vault ""))
        {:root root :vault (vim.fn.expand vault)}
        nil)))

(fn ensure-obsidian-workspaces! []
  (let [ws vim.g.obsidian_workspaces]
    (when (or (not ws) (and (= (type ws) :table) (= (# ws) 0)))
      (let [proj (obsidian-project-vault)
            default (or vim.g.obsidian_default_vault "")]
        (set vim.g.obsidian_workspaces
             (if proj
                 [{:name (vim.fn.fnamemodify (. proj :root) ":t")
                   :path (. proj :vault)}]
                 (if (and (= (type default) :string) (not= default ""))
                     [{:name "notes" :path (vim.fn.expand default)}]
                     [])))))))

(ensure-obsidian-workspaces!)

(fn run-in-term [cmd cwd]
  (let [prev (vim.fn.getcwd)]
    (when (and cwd (not= cwd ""))
      (pcall vim.api.nvim_set_current_dir cwd))
    (pcall (fn [] (vim.cmd (.. "botright split | terminal " cmd))))
    (pcall vim.api.nvim_set_current_dir prev)
    (pcall vim.cmd "startinsert")))

(fn shellescape [s]
  (vim.fn.shellescape s))

(fn markdown-current-file []
  (local file (vim.api.nvim_buf_get_name 0))
  (if (and file (not= file ""))
      file
      nil))

(fn markdown-export-mermaid []
  (local file (markdown-current-file))
  (if (not file)
      (vim.notify "当前 buffer 还没有文件路径，无法导出 mermaid" vim.log.levels.WARN)
      (if (= (vim.fn.executable "mmdc") 0)
          (vim.notify "未找到 mmdc（mermaid-cli）" vim.log.levels.WARN)
          (let [root (project-root [".git" "README.md" "docs"])
                out (.. file ".mermaid.svg")
                cmd (.. "mmdc -q -i " (shellescape file)
                        " -o " (shellescape out)
                        " -e svg -t dark")]
            (run-in-term cmd root)))))

(fn markdown-export-plantuml []
  (local file (markdown-current-file))
  (if (not file)
      (vim.notify "当前 buffer 还没有文件路径，无法导出 plantuml" vim.log.levels.WARN)
      (if (= (vim.fn.executable "plantuml") 0)
          (vim.notify "未找到 plantuml CLI" vim.log.levels.WARN)
          (let [root (project-root [".git" "README.md" "docs"])
                cmd (.. "plantuml -tsvg " (shellescape file))]
            (run-in-term cmd root)))))

(fn markdown-semver-gte? [version major minor patch]
  (let [major0 (tonumber (or (string.match version "^(%d+)") "0"))
        minor0 (tonumber (or (string.match version "^%d+%.(%d+)") "0"))
        patch0 (tonumber (or (string.match version "^%d+%.%d+%.(%d+)") "0"))]
    (or (> major0 major)
        (and (= major0 major) (> minor0 minor))
        (and (= major0 major) (= minor0 minor) (>= patch0 patch)))))

(fn markdown-env-truthy? [value]
  (and value
       (not= value "")
       (not= value "0")
       (not= value "false")
       (not= value "False")
       (not= value "FALSE")
       (not= value "no")
       (not= value "No")
       (not= value "NO")))

(fn markdown-herdr-env? []
  (or (markdown-env-truthy? vim.env.HERDR_ENV)
      (markdown-env-truthy? vim.env.HERDR_SOCKET_PATH)
      (markdown-env-truthy? vim.env.HERDR_PANE_ID)))

(fn markdown-herdr-preview-env? []
  (and (markdown-env-truthy? vim.env.HERDR_ENV)
       (markdown-env-truthy? vim.env.HERDR_SOCKET_PATH)
       (markdown-env-truthy? vim.env.HERDR_PANE_ID)))

(fn markdown-mdview-preview []
  (local file (markdown-current-file))
  (if (not file)
      (vim.notify "当前 buffer 还没有文件路径，无法用 mdview 预览" vim.log.levels.WARN)
      (let [root (project-root [".git" "README.md" "docs"])
            controller (or vim.g.markdown_herdr_preview_controller
                           (vim.fn.expand "~/.trae/skills/herdr-markdown-preview/scripts/herdr_markdown_preview.py"))]
        (if (markdown-herdr-preview-env?)
            (if (or (= (vim.fn.executable "python3") 0)
                    (not= (vim.fn.filereadable controller) 1))
                (vim.notify "Herdr Markdown preview controller 不可用" vim.log.levels.WARN)
                (vim.system ["python3" controller "start" file "--client" "neovim"]
                            {:cwd root :text true}
                            (fn [result]
                              (vim.schedule
                                (fn []
                                  (if (= result.code 0)
                                      (vim.notify "已在相邻 Herdr pane 打开 mdview")
                                      (let [detail (vim.trim (or result.stderr result.stdout ""))]
                                        (vim.notify
                                          (.. "mdview 启动失败："
                                              (if (= detail "")
                                                  (.. "exit " (tostring result.code))
                                                  detail))
                                          vim.log.levels.WARN))))))))
            (if (= (vim.fn.executable "mdview") 0)
                (vim.notify "未找到 mdview；请先安装到 PATH" vim.log.levels.WARN)
                (run-in-term (.. "mdview --backend=text " (shellescape file)) root))))))

(fn markdown-zellij-env? []
  (or (markdown-env-truthy? vim.env.ZELLIJ)
      (markdown-env-truthy? vim.env.ZELLIJ_PANE_ID)))

(fn markdown-herdr-has-pixel-geometry? []
  (if (not (markdown-herdr-env?))
      false
      (let [log-path (vim.fn.expand "~/.config/herdr/herdr-server.log")]
        (if (not= (vim.fn.filereadable log-path) 1)
            false
            (let [geometry
                  (if (= (vim.fn.executable "rg") 1)
                      (vim.fn.system
                        ["rg" "-m" "1"
                         "cell_width_px=[1-9][0-9]*.*cell_height_px=[1-9][0-9]*"
                         log-path])
                      "")]
              (and geometry
                   (not= geometry "")))))))

(fn markdown-herdr-outer-terminal-program []
  (or vim.g.markdown_mdrender_herdr_term_program
      vim.env.HERDR_TERM_PROGRAM
      (when (markdown-herdr-has-pixel-geometry?) "ghostty")))

(fn markdown-zellij-graphics-enabled? []
  (and (markdown-zellij-env?)
       (= (vim.fn.executable "zellij") 1)
       (let [version-output (vim.fn.system ["zellij" "--version"])
             version (or (string.match version-output "(%d+%.%d+%.%d+)") "0.0.0")
             cfg-path (vim.fs.joinpath (vim.fn.expand "~/.config/zellij") "config.kdl")
             cfg-text (if (= (vim.fn.filereadable cfg-path) 1) (_read-all cfg-path) "")]
         (and (markdown-semver-gte? version 0 45 0)
              (not (string.find cfg-text "support_kitty_graphics_protocol false" 1 true))))))

(fn markdown-terminal-program []
  (or vim.g.markdown_mdrender_term_program
      vim.env.MDRENDER_TERM_PROGRAM
      vim.env.TERM_PROGRAM
      (when vim.env.KITTY_WINDOW_ID "kitty")
      (when vim.env.GHOSTTY_RESOURCES_DIR "ghostty")
      (when vim.env.WEZTERM_EXECUTABLE "WezTerm")
      (markdown-herdr-outer-terminal-program)
      ;; On zellij 0.45+, kitty graphics passthrough is supported.
      ;; Herdr/zellij may drop TERM_PROGRAM, so use zellij capability as a fallback.
      (when (markdown-zellij-graphics-enabled?) "kitty")))

(fn markdown-terminal-supports-graphics? []
  (let [term (markdown-terminal-program)]
    (or (= term "ghostty")
        (= term "kitty")
        (= term "WezTerm"))))

(fn markdown-prepare-mdrender-env! []
  (let [term (markdown-terminal-program)]
    (when (and term (not vim.env.TERM_PROGRAM))
      (set vim.env.TERM_PROGRAM term))
    (when (and (markdown-herdr-env?) (not vim.env.HERDR_TERM_PROGRAM) term)
      (set vim.env.HERDR_TERM_PROGRAM term))
    (when (= term "kitty")
      (set vim.env.KITTY_WINDOW_ID (or vim.env.KITTY_WINDOW_ID "1")))
    (when (= term "ghostty")
      (set vim.env.GHOSTTY_RESOURCES_DIR (or vim.env.GHOSTTY_RESOURCES_DIR "1")))
    (when (= term "WezTerm")
      (set vim.env.WEZTERM_EXECUTABLE (or vim.env.WEZTERM_EXECUTABLE "1")))
    (pcall
      (fn []
        ((. (require :md-render.image) :reset_cache))))
    term))

(fn markdown-mdrender-pane-width [subcmd]
  (local win-width (vim.api.nvim_win_get_width 0))
  (local win-info (. (vim.fn.getwininfo (vim.api.nvim_get_current_win)) 1))
  (local textoff (or (and win-info (. win-info :textoff)) 0))
  (local usable (math.max 20 (- win-width textoff)))
  (if (= subcmd "tab")
      usable
      (math.max 20 (- usable 2))))

(fn markdown-debug-upvalue-index [f wanted idx]
  (let [n (or idx 1)
        packed [(debug.getupvalue f n)]
        name (. packed 1)]
    (if (not name)
        nil
        (if (= name wanted)
            n
            (markdown-debug-upvalue-index f wanted (+ n 1))))))

(fn markdown-debug-upvalue-value [f wanted idx]
  (let [n (or idx 1)
        packed [(debug.getupvalue f n)]
        name (. packed 1)
        value (. packed 2)]
    (if (not name)
        nil
        (if (= name wanted)
            value
            (markdown-debug-upvalue-value f wanted (+ n 1))))))

(fn markdown-debug-set-upvalue! [f wanted value]
  (let [idx (markdown-debug-upvalue-index f wanted 1)]
    (when idx
      (debug.setupvalue f idx value)
      true)))

(fn markdown-mdrender-apply-pane-width-patch! []
  (let [packed [(pcall require :md-render.preview)]
        ok (. packed 1)
        preview (. packed 2)]
    (when ok
      (when (not vim.g.markdown_mdrender_pane_width_patch_applied)
        (local default-max-width 4096)
        (local session (markdown-debug-upvalue-value (. preview :show) "Session" 1))
        (local get-or-create-session (markdown-debug-upvalue-value (. preview :toggle) "get_or_create_toggle_session" 1))
        (local install-win-resize-handler
          (and get-or-create-session
               (markdown-debug-upvalue-value get-or-create-session "install_win_resize_handler" 1)))
        (markdown-debug-set-upvalue! (. preview :build_content) "DEFAULT_MAX_WIDTH" default-max-width)
        (when session
          (markdown-debug-set-upvalue! (. session :bind_window) "DEFAULT_MAX_WIDTH" default-max-width))
        (when install-win-resize-handler
          (markdown-debug-set-upvalue! install-win-resize-handler "DEFAULT_MAX_WIDTH" default-max-width))
        (set vim.g.markdown_mdrender_pane_width_patch_applied true))
      true)))

(fn markdown-mdrender-open [subcmd]
  (ensure-plugin "md-render.nvim")
  (if (not (= vim.bo.filetype "markdown"))
      (vim.notify "当前 buffer 不是 markdown，无法打开内嵌浏览态" vim.log.levels.WARN)
      (let [term (markdown-prepare-mdrender-env!)
            _ (markdown-mdrender-apply-pane-width-patch!)
            preview-packed [(pcall require :md-render.preview)]
            preview-ok (. preview-packed 1)
            preview (. preview-packed 2)
            packed [(pcall
                      (fn []
                        (if (not preview-ok)
                            (error "md-render.preview 未加载成功")
                            (if (= subcmd "toggle")
                                ((. preview :toggle))
                                (if (= subcmd "split")
                                    ((. preview :split))
                                    (if (= subcmd "tab")
                                        ((. preview :show_tab))
                                        (if (= subcmd "auto on")
                                            ((. preview :auto_on))
                                            ((. preview :show)))))))))]
            ok (. packed 1)
            err (. packed 2)]
        (when (not ok)
          (vim.notify (.. "MdRender 打开失败：" (tostring err)) vim.log.levels.WARN))
        (when (and ok (not (markdown-terminal-supports-graphics?)))
          (vim.notify "当前 pane 没识别到 Ghostty/Kitty/WezTerm；md-render 可用，但图片类图形渲染可能退化" vim.log.levels.INFO))
        (when (and ok term)
          (vim.notify (.. "MdRender 终端探测：" term) vim.log.levels.DEBUG)))))

(fn markdown-mdrender-float []
  (markdown-mdrender-open nil))

(fn markdown-mdrender-toggle []
  (markdown-mdrender-open "toggle"))

(fn markdown-mdrender-split []
  (markdown-mdrender-open "split"))

(fn markdown-mdrender-tab []
  (markdown-mdrender-open "tab"))

(fn markdown-mdrender-auto []
  (markdown-mdrender-open "auto on"))

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
               (ensure-plugin "md-render.nvim")
               (markdown-prepare-mdrender-env!)
               (markdown-mdrender-apply-pane-width-patch!)
               (vim.keymap.set "n" ",p" (fn [] (pcall vim.cmd "MarkdownPreviewToggle"))
                             {:buffer bufnr :silent true :noremap true :desc "Markdown: Preview"})
               (vim.keymap.set "n" ",r" (fn [] (pcall vim.cmd "RenderMarkdown buf_toggle"))
                             {:buffer bufnr :silent true :noremap true :desc "Markdown: Render toggle"})
               (vim.keymap.set "n" ",v" markdown-mdrender-float
                             {:buffer bufnr :silent true :noremap true :desc "Markdown: Embedded preview"})
               (vim.keymap.set "n" ",b" markdown-mdrender-toggle
                             {:buffer bufnr :silent true :noremap true :desc "Markdown: Browse mode"})
               (vim.keymap.set "n" ",s" markdown-mdrender-split
                             {:buffer bufnr :silent true :noremap true :desc "Markdown: Source/render split"})
               (vim.keymap.set "n" ",t" markdown-mdrender-tab
                             {:buffer bufnr :silent true :noremap true :desc "Markdown: Preview in tab"})
               (vim.keymap.set "n" ",a" markdown-mdrender-auto
                             {:buffer bufnr :silent true :noremap true :desc "Markdown: Auto browse mode"})
               (vim.keymap.set "n" ",g" markdown-mdview-preview
                             {:buffer bufnr :silent true :noremap true :desc "Markdown: mdview live preview"})
               (vim.keymap.set "n" ",m" markdown-export-mermaid
                             {:buffer bufnr :silent true :noremap true :desc "Markdown: Export Mermaid"})
               (vim.keymap.set "n" ",u" markdown-export-plantuml
                             {:buffer bufnr :silent true :noremap true :desc "Markdown: Export PlantUML"}))})

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
               :b {:cmd (fn []
                         (ensure-plugin "git-blame.nvim")
                         (pcall vim.cmd "GitBlameToggle"))
                   :desc "Blame: Toggle"}
               :s {:cmd (fn []
                         (ensure-plugin "advanced-git-search.nvim")
                         (pcall vim.cmd "AdvancedGitSearch"))
                   :desc "Search: Advanced"}
               :i {:cmd (fn []
                         (ensure-plugin "inlinediff-nvim")
                         (pcall vim.cmd "InlineDiff toggle"))
                   :desc "InlineDiff: Toggle"}
               :u {:cmd (fn []
                         (ensure-plugin "lazyUrlUpdate.nvim")
                         (pcall vim.cmd "LazyUrlUpdate"))
                   :desc "LazyUrl: Update plugin under cursor"}
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
  :<leader>j {:name "+jujutsu"
               :j {:cmd (fn []
                           (let [packed [(pcall require :gentlewind.modules.config.dev_tools)]
                                 ok (. packed 1)
                                 dev-tools (. packed 2)]
                             (when ok
                               ((. dev-tools :activate_jj_hydra)))))
                   :desc "JJ: Hydra"}}
  :<leader>d {:cmd (fn [] ((. (require :gentlewind.modules.config.dev_tools) :toggle_debug_hydra)))
               :desc "Debug 菜单"}
  :<leader>a {:cmd (fn [] ((. (require :gentlewind.modules.config.dev_tools) :activate_agentic_hydra)))
               :desc "AI 菜单"}
  :<leader>r {:name "+remote"
              :i {:cmd (fn [] (ensure-plugin "distant.nvim") (pcall vim.cmd "DistantInstall"))
                  :desc "Distant: Install"}
              :c {:cmd (fn [] (ensure-plugin "distant.nvim") (pcall vim.cmd "DistantConnect"))
                  :desc "Distant: Connect"}
              :s {:cmd (fn [] (ensure-plugin "nvim-dev-container") (pcall vim.cmd "DevcontainerStart"))
                  :desc "Devcontainer: Start"}
              :a {:cmd (fn [] (ensure-plugin "nvim-dev-container") (pcall vim.cmd "DevcontainerAttach"))
                  :desc "Devcontainer: Attach"}
              :e {:cmd (fn [] (ensure-plugin "nvim-dev-container") (pcall vim.cmd "DevcontainerExec"))
                  :desc "Devcontainer: Exec"}
              :l {:cmd (fn [] (ensure-plugin "nvim-dev-container") (pcall vim.cmd "DevcontainerLogs"))
                  :desc "Devcontainer: Logs"}}
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
                  :desc "HTTP/Hurl 菜单"}
              :c {:cmd (fn [] (ensure-plugin "nvim-coverage") (pcall vim.cmd "CoverageToggle"))
                  :desc "Coverage: Toggle"}
              :m {:cmd (fn [] (ensure-plugin "time-machine.nvim") (pcall vim.cmd "TimeMachineToggle"))
                  :desc "TimeMachine: Toggle"}}})

;; Files / Notes / Jump
(gentlewind.use_keybind
  {:<leader>f {:name "+files"
               :o {:cmd (fn [] (ensure-plugin "oil.nvim") (pcall vim.cmd "Oil"))
                   :desc "Oil: Open"}
               :O {:cmd (fn [] (ensure-plugin "oil.nvim") (pcall vim.cmd "Oil --float"))
                   :desc "Oil: Float"}
               :r {:cmd (fn [] (ensure-plugin "nvim-genghis") (pcall vim.cmd "Genghis renameFile"))
                   :desc "Rename file"}
               :m {:cmd (fn [] (ensure-plugin "nvim-genghis") (pcall vim.cmd "Genghis moveAndRenameFile"))
                   :desc "Move/Rename file"}
               :d {:cmd (fn [] (ensure-plugin "nvim-genghis") (pcall vim.cmd "Genghis trashFile"))
                   :desc "Trash file"}
               :y {:cmd (fn [] (ensure-plugin "nvim-genghis") (pcall vim.cmd "Genghis copyFilepath"))
                   :desc "Copy filepath"}}

   :<leader>n {:name "+notes"
               :o {:cmd (fn [] (ensure-plugin "obsidian.nvim") (pcall vim.cmd "Obsidian"))
                   :desc "Obsidian: Menu"}
               :t {:cmd (fn [] (ensure-plugin "obsidian.nvim") (pcall vim.cmd "Obsidian today"))
                   :desc "Obsidian: Today"}
               :s {:cmd (fn [] (ensure-plugin "obsidian.nvim") (pcall vim.cmd "Obsidian search"))
                   :desc "Obsidian: Search"}
               :q {:cmd (fn [] (ensure-plugin "obsidian.nvim") (pcall vim.cmd "Obsidian quick_switch"))
                   :desc "Obsidian: Quick switch"}
               :b {:cmd (fn [] (ensure-plugin "obsidian.nvim") (pcall vim.cmd "Obsidian backlinks"))
                   :desc "Obsidian: Backlinks"}}

   :<leader>w {:name "+warp"
               :w {:cmd (fn [] (ensure-plugin "warp.nvim") (pcall vim.cmd "Warp"))
                   :desc "Warp: Jump to path/url"}
               :h {:cmd (fn []
                         ;; hodur 自带可配置热键（默认 <C-g>）。这里保留一个显式入口给 which-key。
                         (ensure-plugin "hodur.nvim")
                         (vim.notify "Hodur 默认热键 <C-g>：打开 file(:line[:col]) 或复制 URL" vim.log.levels.INFO))
                   :desc "Hodur: Hint"}}})

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

;; 规范 Mason 运行环境：工具走 Mason bin，Go 包安装强制走 Homebrew Go，避免继承 GVM 的旧 GOROOT/GOPATH。
(let [prepend-path
      (fn [dir]
        (when (and dir (not= dir "") (= (vim.fn.isdirectory dir) 1))
          (let [items (vim.split (or vim.env.PATH "") ":" {:plain true})
                filtered []]
            (each [_ item (ipairs items)]
              (when (and (not= item "") (not= item dir))
                (table.insert filtered item)))
            (table.insert filtered 1 dir)
            (set vim.env.PATH (table.concat filtered ":")))))
      gvm-path? (fn [value] (and value (string.find value "/.gvm/" 1 true)))
      local-bin (vim.fn.expand "~/.local/bin")
      elan-bin (vim.fn.expand "~/.elan/bin")
      mason-bin (.. (vim.fn.stdpath :data) "/mason/bin")
      brew-go-bins ["/opt/homebrew/opt/go/bin"
                    "/opt/homebrew/bin"
                    "/usr/local/opt/go/bin"
                    "/usr/local/bin"]]
  ;; GUI / Zellij 启动 Neovim 时也能找到 traex、uvx、elan、lean 与 lake。
  (prepend-path local-bin)
  (prepend-path elan-bin)
  (prepend-path mason-bin)
  (var brew-go-bin nil)
  (each [_ dir (ipairs brew-go-bins)]
    (when (and (not brew-go-bin)
               (= (vim.fn.executable (.. dir "/go")) 1))
      (set brew-go-bin dir)))
  (when brew-go-bin
    (prepend-path brew-go-bin)
    (when (gvm-path? vim.env.GOROOT)
      (set vim.env.GOROOT nil))
    (when (gvm-path? vim.env.GOPATH)
      (set vim.env.GOPATH nil))))

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

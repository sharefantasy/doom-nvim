;; gentlewind.modules.langs.lean
;; Lean 4 IDE and TraeX collaboration support for gentlewind-nvim

(local lean {})
(var _agent-hydra nil)

(set lean.settings {:disable_treesitter true
                    :plugin_config {:mappings false
                                    :abbreviations {:leader "\\"}
                                    :graphics {:enabled true}
                                    :inlay_hint {:enabled true}
                                    :progress_bars {:enable true}
                                    :stderr {:enable true :height 5}
                                    :lsp {:enhanced_handlers {:hover true
                                                              :diagnostics true}}
                                    :infoview {:autoopen true
                                               :orientation :vertical
                                               :width 0.32
                                               :separate_tab false
                                               :update_cooldown 50
                                               :view_options {:use_widgets true
                                                              :show_types true
                                                              :show_instances false
                                                              :show_hidden_assumptions false
                                                              :show_let_values true
                                                              :show_term_goals true
                                                              :reverse false}}}
                    :agent_default_mode :suggest})

(fn notify [message level]
  (vim.notify message (or level vim.log.levels.INFO) {:title :Lean}))

(fn ensure-lazy-plugin [name]
  (let [packed [(pcall require :lazy)]
        ok (. packed 1)
        lazy (. packed 2)]
    (when ok
      (pcall (fn []
               ((. lazy :load) {:plugins [name]}))))
    ok))

(fn ensure-lean []
  (ensure-lazy-plugin :lean.nvim)
  (let [packed [(pcall require :lean)]
        ok (. packed 1)
        module (. packed 2)]
    (when (not ok)
      (notify (.. "lean.nvim 未加载：" module) vim.log.levels.ERROR))
    (if ok module nil)))

(fn ensure-agentic []
  (ensure-lazy-plugin :agentic.nvim)
  (let [packed [(pcall require :agentic)]
        ok (. packed 1)
        module (. packed 2)]
    (when (not ok)
      (notify (.. "agentic.nvim 未加载：" module) vim.log.levels.ERROR))
    (if ok module nil)))

(fn ensure-lean-tools []
  (local missing [])
  (each [_ executable (ipairs [:elan :lean :lake])]
    (when (= (vim.fn.executable executable) 0)
      (table.insert missing executable)))
  (if (> (length missing) 0)
      (do
        (notify (.. "缺少 Lean 工具：" (table.concat missing ", ")
                    "。请安装 elan-init 并执行 `elan default stable`。")
                vim.log.levels.ERROR)
        false)
      true))

(fn lean-root [bufnr]
  (let [name (vim.api.nvim_buf_get_name (or bufnr 0))
        root (and (not= name "")
                  (vim.fs.root name
                               [:lakefile.toml :lakefile.lean :lean-toolchain]))]
    (or root (vim.fn.getcwd))))

(fn align-tab-root [bufnr]
  (let [root (lean-root bufnr)]
    ;; Agentic 的 ACP session/new 使用 vim.fn.getcwd()；用 tab-local cwd 对齐项目，
    ;; 避免影响其他 tab 或 Neovim 的全局工作目录。
    (when (and root (not= root ""))
      (vim.cmd (.. "tcd " (vim.fn.fnameescape root)))
      (set vim.t.gentlewind_lean_root root))
    root))

(fn with-source-window [winid callback]
  (if (and winid (vim.api.nvim_win_is_valid winid))
      (vim.api.nvim_win_call winid callback)
      (callback)))

(fn open-infoview [winid]
  (when (and (ensure-lean-tools) (ensure-lean))
    (with-source-window winid
      (fn []
        (let [packed [(pcall require :lean.infoview)]
              ok (. packed 1)
              infoview (. packed 2)]
          (if ok
              ((. infoview :open))
              (notify (.. "无法打开 Lean Infoview：" infoview)
                      vim.log.levels.ERROR)))))))

(fn close-infoview []
  (let [packed [(pcall require :lean.infoview)]
        ok (. packed 1)
        infoview (. packed 2)]
    (when ok
      (pcall (. infoview :close)))))

(fn open-workbench []
  (let [source-win (vim.api.nvim_get_current_win)
        bufnr (vim.api.nvim_get_current_buf)]
    (align-tab-root bufnr)
    (open-infoview source-win)
    (vim.schedule (fn []
                    (when (vim.api.nvim_win_is_valid source-win)
                      (vim.api.nvim_set_current_win source-win))))))

(fn close-workbench []
  (close-infoview))

(fn mode-instructions [mode]
  (match mode
    :explain
    ["解释当前 goal、每个 hypothesis 的含义，以及可能使用的 Mathlib theorem。"
     "不要修改文件。"]
    :solve
    ["完成当前 theorem。可以修改当前 Lean 文件，但不要修改无关定义。"
     "优先复用 Mathlib；禁止新增 sorry、axiom 或不安全占位。"
     "修改后调用 Lean MCP 检查，并运行 lake build 与 lean_verify。"]
    _ ["给出 1～3 个下一步 tactic，并说明各自为什么适用。"
       "优先给最小、稳定、可读的证明；不要直接修改文件。"]))

(fn normalize-agent-mode [mode]
  (let [value (string.lower (or mode ""))]
    (if (vim.tbl_contains [:explain :suggest :solve] value)
        value
        lean.settings.agent_default_mode)))

(fn agent-prompt [mode goal file row col]
  (table.concat (vim.list_extend ["请协助处理当前 Lean 证明。"
                                  ""
                                  (.. "文件：" file)
                                  (string.format "位置：%d:%d" row (+ col 1))
                                  ""
                                  "要求："]
                                 (vim.list_extend (vim.tbl_map (fn [line]
                                                                 (.. "- " line))
                                                               (mode-instructions mode))
                                                  ["- 先读取当前文件、诊断和下面的 goal，再给出结论。"
                                                   "- 不要猜测 Mathlib API；优先使用 lean_local_search、lean_leansearch 或 lean_loogle。"
                                                   ""
                                                   "当前 goal："
                                                   ""
                                                   "```lean"
                                                   (if (and goal
                                                            (not= (vim.trim goal)
                                                                  ""))
                                                       goal
                                                       "（当前没有可显示的 goal）")
                                                   "```"]))
                "\n"))

(fn append-agent-prompt [session prompt]
  (let [widget (. session :widget)
        input-buf (and widget widget.buf_nrs widget.buf_nrs.input)]
    (if (not (and input-buf (vim.api.nvim_buf_is_valid input-buf)))
        (notify "Agentic 输入 buffer 不可用" vim.log.levels.ERROR)
        (let [current-lines (vim.api.nvim_buf_get_lines input-buf 0 -1 false)
              current (vim.trim (table.concat current-lines "\n"))
              text (if (= current "")
                       prompt
                       (.. current "\n\n---\n\n" prompt))]
          (vim.api.nvim_buf_set_lines input-buf 0 -1 false
                                      (vim.split text "\n" {:plain true}))
          (: widget :show {:focus_prompt true})))))

(fn with-agent-session [callback]
  (when (ensure-agentic)
    (let [packed [(pcall require :agentic.session_registry)]
          ok (. packed 1)
          registry (. packed 2)]
      (if ok
          ((. registry :get_session_for_tab_page) nil callback)
          (notify (.. "无法访问 Agentic session：" registry)
                  vim.log.levels.ERROR)))))

(fn capture-agent-selection []
  (let [mode (. (vim.api.nvim_get_mode) :mode)
        visual? (or (= mode :v) (= mode :V) (= mode "\022"))]
    (when visual?
      (ensure-agentic)
      (let [packed [(pcall require :agentic.ui.code_selection)]
            ok (. packed 1)
            code-selection (. packed 2)]
        (when ok
          ((. code-selection :get_selected_text)))))))

(fn add-agent-context [bufnr selection]
  (with-agent-session (fn [session]
                        (when selection
                          (: session.code_selection :add selection))
                        (: session :add_file_to_session bufnr)
                        (: session :add_current_line_diagnostics_to_context
                           bufnr)
                        (: session.widget :show {:focus_prompt false}))))

(fn request-goal [bufnr winid position callback]
  (if (not (and (ensure-lean-tools) (ensure-lean)))
      (callback nil "Lean 环境不可用")
      (with-source-window winid
        (fn []
          (let [packed [(pcall require :lean.infoview)]
                ok (. packed 1)
                infoview (. packed 2)]
            (if (not ok)
                (callback nil infoview)
                (do
                  ((. infoview :open))
                  (let [on-result (fn [element]
                                    (let [rendered [(pcall (fn []
                                                             (: element
                                                                :to_string)))]
                                          render-ok (. rendered 1)
                                          text (. rendered 2)]
                                      (callback (if render-ok text nil)
                                                (if render-ok nil text))))
                        result [(pcall (fn []
                                         ((. infoview :contents_at) position
                                                                    {:buf bufnr
                                                                     :callback on-result})))]]
                    (when (not (. result 1))
                      (callback nil (. result 2)))))))))))

(fn ask-agent [requested-mode]
  (let [mode (normalize-agent-mode requested-mode)
        bufnr (vim.api.nvim_get_current_buf)
        winid (vim.api.nvim_get_current_win)
        position (vim.api.nvim_win_get_cursor winid)
        file-name (vim.api.nvim_buf_get_name bufnr)
        display-file (if (= file-name "") "[未命名 Lean buffer]"
                         (vim.fn.fnamemodify file-name ":."))
        selection (capture-agent-selection)]
    (align-tab-root bufnr)
    (request-goal bufnr winid position
                  (fn [goal err]
                    (vim.schedule (fn []
                                    (when err
                                      (notify (.. "读取当前 goal 失败："
                                                  err)
                                              vim.log.levels.WARN))
                                    (add-agent-context bufnr selection)
                                    (with-agent-session (fn [session]
                                                          (append-agent-prompt session
                                                                               (agent-prompt mode
                                                                                             goal
                                                                                             display-file
                                                                                             (. position
                                                                                                1)
                                                                                             (. position
                                                                                                2)))))))))))

(fn run-lake-build []
  (if (= (vim.fn.executable :lake) 0)
      (notify "未找到 lake" vim.log.levels.ERROR)
      (let [root (lean-root 0)]
        (vim.cmd "botright 12new")
        (let [job (vim.fn.jobstart [:lake :build] {:cwd root :term true})]
          (if (> job 0)
              (vim.cmd :startinsert)
              (notify "启动 lake build 失败" vim.log.levels.ERROR))))))

(fn lean-health []
  (ensure-lazy-plugin :lean.nvim)
  (vim.cmd "checkhealth lean"))

(fn lean-live-code [opts]
  (let [bufnr (vim.api.nvim_get_current_buf)]
    (if (not= (. (. vim.bo bufnr) :filetype) :lean)
        (notify "当前 buffer 不是 Lean 文件" vim.log.levels.WARN)
        (let [all-lines (vim.api.nvim_buf_get_lines bufnr 0 -1 false)
              ranged? (> (or opts.range 0) 0)
              selected-lines (if ranged?
                                 (vim.api.nvim_buf_get_lines bufnr
                                                             (- opts.line1 1)
                                                             opts.line2 false)
                                 all-lines)
              imports (if ranged?
                          (vim.tbl_filter (fn [line]
                                            (string.match line "^%s*import%s+"))
                                          all-lines)
                          [])
              code (if (and ranged? (> (length imports) 0))
                       (table.concat (vim.list_extend (vim.deepcopy imports)
                                                      (vim.list_extend [""]
                                                                       selected-lines))
                                     "\n")
                       (table.concat selected-lines "\n"))
              url (.. "https://live.lean-lang.org/#code=" (vim.uri_encode code))
              (process err) (vim.ui.open url)]
          (if process
              (notify (if ranged?
                          "已在 Lean Live 打开 imports 与当前选区"
                          "已在 Lean Live 打开当前文件"))
              (notify (.. "无法打开 Lean Live：" err) vim.log.levels.ERROR))))))

(fn launch-lean-workspace [file]
  (let [launcher (vim.fs.joinpath (vim.fn.stdpath :config) :tools
                                  :lean-workbench.sh)]
    (if (= (vim.fn.executable launcher) 0)
        (notify (.. "Lean 工作台启动脚本不可执行：" launcher)
                vim.log.levels.ERROR)
        (vim.system [launcher file] {:text true}
                    (fn [result]
                      (vim.schedule (fn []
                                      (if (= result.code 0)
                                          (notify "已打开 Lean Kitty + Zellij 工作台")
                                          (notify (.. "启动 Lean 工作台失败："
                                                      (or (vim.trim (or result.stderr
                                                                        ""))
                                                          result.code))
                                                  vim.log.levels.ERROR)))))))))

(fn open-lean-workspace []
  (let [bufnr (vim.api.nvim_get_current_buf)
        file (vim.api.nvim_buf_get_name bufnr)
        filetype (. (. vim.bo bufnr) :filetype)
        modified? (. (. vim.bo bufnr) :modified)]
    (if (not= filetype :lean)
        (notify "当前 buffer 不是 Lean 文件" vim.log.levels.WARN)
        (if (= file "")
            (notify "请先保存 Lean 文件，再打开图形模式"
                    vim.log.levels.WARN)
            (if modified?
                (notify "当前 Lean 文件有未保存修改；请先保存，避免图形窗口读取旧内容"
                        vim.log.levels.WARN)
                (if vim.env.LEAN_WORKBENCH
                    (notify "当前已经在 Lean Kitty + Zellij 工作台中")
                    (if (= (vim.fn.executable :kitty) 0)
                        (notify "未找到 Kitty；请先安装 `brew install --cask kitty`"
                                vim.log.levels.ERROR)
                        (if (= (vim.fn.executable :resvg) 0)
                            (notify "未找到 resvg；请先安装 `brew install resvg`"
                                    vim.log.levels.ERROR)
                            (launch-lean-workspace file)))))))))

(fn wait-for-lean-client [bufnr remaining]
  (when (vim.api.nvim_buf_is_valid bufnr)
    (let [client ((. (require :lean.lsp) :client_for) bufnr)]
      (if (and client client.initialized (not (: client :is_stopped)))
          (do
            (tset (. vim.b bufnr) :lean_gentlewind_recovering nil)
            (notify "Lean language server 已重新连接"))
          (if (> remaining 0)
              (vim.defer_fn (fn [] (wait-for-lean-client bufnr (- remaining 1)))
                100)
              (do
                (tset (. vim.b bufnr) :lean_gentlewind_recovering nil)
                (notify "Lean language server 重连超时；请运行 :checkhealth lean 并查看 :messages"
                        vim.log.levels.ERROR)))))))

(fn recover-lean []
  (let [bufnr (vim.api.nvim_get_current_buf)]
    (if (not= (. (. vim.bo bufnr) :filetype) :lean)
        (notify "当前 buffer 不是 Lean 文件" vim.log.levels.WARN)
        (when (and (ensure-lean-tools) (ensure-lean))
          (let [lean-lsp (require :lean.lsp)
                client ((. lean-lsp :client_for) bufnr)]
            (if (and client client.initialized (not (: client :is_stopped)))
                (do
                  ;; 若 LSP 已重新附着但死亡标记因竞态残留，按 lean.nvim 的
                  ;; LspAttach 恢复路径清除标记并刷新当前 URI。
                  (when (. (. vim.b bufnr) :lean_lsp_died)
                    (tset (. vim.b bufnr) :lean_lsp_died nil)
                    ((. (require :lean.infoview) :__update_pin_by_uri) (vim.uri_from_bufnr bufnr)))
                  ((. lean-lsp :restart_file) bufnr)
                  (notify "正在重启当前 Lean 文件 worker"))
                (when (not (. (. vim.b bufnr) :lean_gentlewind_recovering))
                  (tset (. vim.b bufnr) :lean_gentlewind_recovering true)
                  (notify "Lean language server 已脱附，正在重新连接…"
                          vim.log.levels.WARN)
                  (vim.lsp.enable :leanls)
                  (wait-for-lean-client bufnr 100))))))))

(fn call-agentic [method & opts]
  (let [agentic (ensure-agentic)]
    (when agentic
      (let [callback (. agentic method)]
        (when callback
          (callback (unpack opts)))))))

(fn ensure-agent-hydra []
  (when (not _agent-hydra)
    (let [packed [(pcall require :hydra)]
          ok (. packed 1)
          Hydra (. packed 2)]
      (when ok
        (set _agent-hydra
             (Hydra {:name "Lean Agent"
                     :mode [:n :x]
                     :hint (table.concat [" Lean Agent (TraeX)"
                                          ""
                                          " _e_: explain goal     _n_: next tactics     _s_: solve theorem"
                                          " _f_: add file         _d_: diagnostics     _o_: toggle chat"
                                          " _l_: rotate layout    _x_: stop generation _q_: quit"]
                                         "\n")
                     :config {:color :teal
                              :invoke_on_body true
                              :hint {:border :rounded :position :middle}}
                     :heads [[:e
                              (fn [] (ask-agent :explain))
                              {:exit true :desc "Explain goal"}]
                             [:n
                              (fn [] (ask-agent :suggest))
                              {:exit true :desc "Suggest tactics"}]
                             [:s
                              (fn [] (ask-agent :solve))
                              {:exit true :desc "Solve theorem"}]
                             [:f
                              (fn []
                                (call-agentic :add_file {:focus_prompt false}))
                              {:desc "Add file"}]
                             [:d
                              (fn []
                                (call-agentic :add_current_line_diagnostics
                                              {:focus_prompt false}))
                              {:desc "Add diagnostics"}]
                             [:o
                              (fn []
                                (call-agentic :toggle
                                              {:auto_add_to_context false}))
                              {:desc "Toggle chat"}]
                             [:l
                              (fn []
                                (call-agentic :rotate_layout
                                              [:bottom :right :left]))
                              {:desc "Rotate layout"}]
                             [:x
                              (fn [] (call-agentic :stop_generation))
                              {:desc "Stop generation" :nowait true}]
                             [:q nil {:exit true :nowait true :desc :Quit}]]})))))
  _agent-hydra)

(fn open-agent-menu []
  (let [hydra (ensure-agent-hydra)]
    (if hydra
        (: hydra :activate)
        (vim.ui.select [:explain :suggest :solve] {:prompt "Lean Agent action"}
                       (fn [choice]
                         (when choice
                           (ask-agent choice)))))))

(fn map-lean-buffer [bufnr]
  (local map (fn [mode lhs rhs desc]
               (vim.keymap.set mode lhs rhs
                               {:buffer bufnr
                                :silent true
                                :noremap true
                                : desc})))
  (map :n ",i" (fn [] (vim.cmd :LeanInfoviewToggle)) "Lean: Toggle Infoview")
  (map :n ",p" (fn [] (vim.cmd :LeanInfoviewPinTogglePause)) "Lean: Pause pin")
  (map :n ",x" (fn [] (vim.cmd :LeanInfoviewAddPin)) "Lean: Add pin")
  (map :n ",c" (fn [] (vim.cmd :LeanInfoviewClearPins)) "Lean: Clear pins")
  (map :n ",s" (fn [] (vim.cmd :LeanInfoviewAcceptSuggestion))
       "Lean: Accept suggestion")
  (map :n ",<Tab>" (fn [] (vim.cmd :LeanGotoInfoview)) "Lean: Go to Infoview")
  (map :n ",\\" (fn [] (vim.cmd :LeanAbbreviationsReverseLookup))
       "Lean: Unicode lookup")
  (map :n ",r" recover-lean "Lean: Recover server or restart file")
  (map :n ",g" (fn [] (vim.cmd :LeanGoal)) "Lean: Show goal")
  (map :n ",t" (fn [] (vim.cmd :LeanTermGoal)) "Lean: Show term goal")
  (map :n ",v" (fn [] (vim.cmd :LeanInfoviewViewOptions)) "Lean: View options")
  (map :n ",w" open-workbench "Lean: Open workbench")
  (map :n ",q" close-workbench "Lean: Close workbench")
  (map :n ",a" open-agent-menu "Lean: Agent menu")
  (map :x ",a" (fn [] (ask-agent :suggest)) "Lean: Ask about selection")
  (map :n ",l" (fn [] (vim.cmd :LeanLive)) "Lean: Open file in Lean Live")
  (map :x ",l" (fn [] (vim.cmd "'<,'>LeanLive"))
       "Lean: Open selection in Lean Live")
  (map :n ",o" open-lean-workspace "Lean: Open Kitty + Zellij workspace")
  (map :n ",b" run-lake-build "Lean: Lake build")
  (map :n ",h" lean-health "Lean: Check health")
  (map :n :K (fn [] (vim.cmd :LeanHover)) "Lean: Interactive hover"))

(set lean.packages
     {:lean-nvim {:repo :Julian/lean.nvim
                  :event ["BufReadPre *.lean" "BufNewFile *.lean"]
                  :init (fn []
                          (set vim.g.lean_config
                               (vim.deepcopy lean.settings.plugin_config)))}})

(set lean.configs {})
(set lean.autocmds
     [{:FileType :lean
       :callback (fn [args]
                   (when (not (. (. vim.b args.buf)
                                 :lean_gentlewind_initialized))
                     (tset (. vim.b args.buf) :lean_gentlewind_initialized true)
                     (ensure-lean-tools)
                     (map-lean-buffer args.buf)))}
      {:LspAttach "*"
       :callback (fn [args]
                   (when (= (. (. vim.bo args.buf) :filetype) :lean)
                     ;; 通用 LSP 模块也在 LspAttach 设置 K；延迟一拍确保 Lean 的交互式 hover 最终生效。
                     (vim.schedule (fn []
                                     (when (and (vim.api.nvim_buf_is_valid args.buf)
                                                (= (. (. vim.bo args.buf)
                                                      :filetype)
                                                   :lean))
                                       (vim.keymap.set :n :K
                                                       (fn []
                                                         (vim.cmd :LeanHover))
                                                       {:buffer args.buf
                                                        :silent true
                                                        :noremap true
                                                        :desc "Lean: Interactive hover"}))))))}])

(set lean.cmds [[:LeanWorkbenchOpen
                 open-workbench
                 {:desc "Open the Lean source and Infoview workspace"}]
                [:LeanWorkbenchClose
                 close-workbench
                 {:desc "Close the Lean Infoview workspace"}]
                [:LeanAgentAsk
                 (fn [opts] (ask-agent opts.args))
                 {:nargs "?"
                  :complete (fn [] [:explain :suggest :solve])
                  :desc "Ask TraeX about the current Lean goal"}]
                [:LeanAgentExplain
                 (fn [] (ask-agent :explain))
                 {:desc "Explain current Lean goal"}]
                [:LeanAgentSuggest
                 (fn [] (ask-agent :suggest))
                 {:desc "Suggest Lean tactics"}]
                [:LeanAgentSolve
                 (fn [] (ask-agent :solve))
                 {:desc "Solve current Lean theorem"}]
                [:LeanRecover
                 recover-lean
                 {:desc "Reconnect leanls or restart the current Lean file"}]
                [:LeanLive
                 lean-live-code
                 {:range true
                  :desc "Open the current Lean buffer or range in Lean Live"}]
                [:LeanGraphics
                 open-lean-workspace
                 {:desc "Open the current Lean file in the Kitty and Zellij workspace"}]
                [:LeanWorkspace
                 open-lean-workspace
                 {:desc "Open the current Lean file in the Kitty and Zellij workspace"}]
                [:LeanBuild
                 run-lake-build
                 {:desc "Run lake build in a terminal split"}]])

(set lean.binds [])

{:packages lean.packages
 :configs lean.configs
 :settings lean.settings
 :autocmds lean.autocmds
 :cmds lean.cmds
 :binds lean.binds}

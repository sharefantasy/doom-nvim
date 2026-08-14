;; gentlewind.modules.langs.tlaplus
;; TLA+/PlusCal editing, verification and TraeX collaboration

(local tlaplus {})
(local langs-utils (require :gentlewind.modules.langs.utils))
(local diagnostic-namespace (vim.api.nvim_create_namespace :gentlewind-tlaplus))
(local tasks {})
(local task-tokens {})
(local cancelled {})
(local output-buffers {})
(local output-windows {})
(local graph-windows {})
(local last-output {})

(set tlaplus.settings {:disable_treesitter false
                       :treesitter_grammars :tlaplus
                       :check_on_save true
                       :check_timeout_ms 30000
                       :output_width 0.38
                       :smoke_seconds 5
                       :tool_version :v1.7.4
                       :agent_default_mode :debug})

(fn notify [message level]
  (vim.notify message (or level vim.log.levels.INFO) {:title :TLA+}))

(fn tool-script []
  (vim.fs.joinpath (vim.fn.stdpath :config) :tools :tlaplus-toolchain.sh))

(fn pinned-jar []
  (or (and vim.env.TLA2TOOLS_JAR (not= vim.env.TLA2TOOLS_JAR "")
           vim.env.TLA2TOOLS_JAR)
      (vim.fs.joinpath (or vim.env.XDG_DATA_HOME
                           (vim.fn.expand "~/.local/share"))
                       :gentlewind :tlaplus tlaplus.settings.tool_version
                       :tla2tools.jar)))

(fn toolchain-ready? []
  (and (= (vim.fn.executable :java) 1) (= (vim.fn.executable (tool-script)) 1)
       (= (vim.fn.filereadable (pinned-jar)) 1)))

(fn ensure-tool-script []
  (let [script (tool-script)]
    (if (= (vim.fn.executable script) 1)
        true
        (do
          (notify (.. "TLA+ 工具脚本不可执行：" script)
                  vim.log.levels.ERROR)
          false))))

(fn cfg-directive? [line]
  (var matched false)
  (each [_ directive (ipairs [:SPECIFICATION
                              :INIT
                              :NEXT
                              :INVARIANT
                              :PROPERTY
                              :CONSTANT
                              :CONSTANTS
                              :CONSTRAINT
                              :ACTION_CONSTRAINT
                              :CHECK_DEADLOCK])]
    (when (string.match line (.. "^%s*" directive "%f[%W]"))
      (set matched true)))
  matched)

(fn detect-cfg-filetype [bufnr]
  (when (and (vim.api.nvim_buf_is_valid bufnr)
             (not= (. (. vim.bo bufnr) :filetype) :tlaplusconfig))
    (let [path (vim.api.nvim_buf_get_name bufnr)
          sibling (string.gsub path "%.cfg$" :.tla)
          line-count (vim.api.nvim_buf_line_count bufnr)
          lines (vim.api.nvim_buf_get_lines bufnr 0 (math.min line-count 80)
                                            false)
          looks-like-tlc (or (= (vim.fn.filereadable sibling) 1)
                             (vim.tbl_contains (vim.tbl_map cfg-directive?
                                                            lines)
                                               true))]
      (when looks-like-tlc
        (tset (. vim.bo bufnr) :filetype :tlaplusconfig)))))

(vim.filetype.add {:extension {:tla :tlaplus}})

(fn current-spec [quiet?]
  (let [bufnr (vim.api.nvim_get_current_buf)
        filetype (. (. vim.bo bufnr) :filetype)
        path (vim.api.nvim_buf_get_name bufnr)
        spec (if (= filetype :tlaplusconfig)
                 (string.gsub path "%.cfg$" :.tla)
                 path)]
    (if (= path "")
        (do
          (when (not quiet?)
            (notify "请先保存 TLA+ 文件" vim.log.levels.WARN))
          nil)
        (if (not (or (= filetype :tlaplus) (= filetype :tlaplusconfig)))
            (do
              (when (not quiet?)
                (notify "当前 buffer 不是 TLA+ 文件或 TLC 配置"
                        vim.log.levels.WARN))
              nil)
            (if (not= (vim.fn.fnamemodify spec ":e") :tla)
                (do
                  (when (not quiet?)
                    (notify "无法定位对应的 .tla 文件"
                            vim.log.levels.ERROR))
                  nil)
                (if (= (vim.fn.filereadable spec) 0)
                    (do
                      (when (not quiet?)
                        (notify (.. "TLA+ 文件不存在：" spec)
                                vim.log.levels.ERROR))
                      nil)
                    spec))))))

(fn source-buffer [spec]
  (let [bufnr (vim.fn.bufnr spec)]
    (if (>= bufnr 0)
        bufnr
        (vim.fn.bufadd spec))))

(fn project-root [spec]
  (or (vim.fs.root spec [:.git]) (vim.fn.fnamemodify spec ":h")))

(fn align-tab-root [spec]
  (let [root (project-root spec)]
    (when (and root (not= root ""))
      (vim.cmd (.. "tcd " (vim.fn.fnameescape root)))
      (set vim.t.gentlewind_tlaplus_root root))
    root))

(fn output-name [bufnr]
  (let [source (vim.api.nvim_buf_get_name bufnr)
        module-name (if (= source "") :session
                        (vim.fn.fnamemodify source ":t:r"))
        identity (if (= source "") :current
                     (string.sub (vim.fn.sha256 source) 1 12))]
    (.. "tlaplus://results/" module-name "-" identity)))

(fn ensure-output-buffer [bufnr]
  (let [existing (. output-buffers bufnr)]
    (if (and existing (vim.api.nvim_buf_is_valid existing))
        existing
        (let [buffer (vim.api.nvim_create_buf false true)]
          (tset output-buffers bufnr buffer)
          (vim.api.nvim_buf_set_name buffer (output-name bufnr))
          (tset (. vim.bo buffer) :buftype :nofile)
          (tset (. vim.bo buffer) :bufhidden :hide)
          (tset (. vim.bo buffer) :swapfile false)
          (tset (. vim.bo buffer) :modifiable false)
          (tset (. vim.bo buffer) :filetype :tlaplusoutput)
          buffer))))

(fn render-output [bufnr text]
  (when (vim.api.nvim_buf_is_valid bufnr)
    (let [lines (vim.split (if (= text "") " " text) "\n"
                           {:plain true :trimempty false})]
      (tset (. vim.bo bufnr) :modifiable true)
      (vim.api.nvim_buf_set_lines bufnr 0 -1 false lines)
      (tset (. vim.bo bufnr) :modifiable false))))

(fn close-window [winid]
  (when (and winid (vim.api.nvim_win_is_valid winid))
    (pcall vim.api.nvim_win_close winid true)))

(fn open-output [source-buf focus?]
  (let [buffer (ensure-output-buffer source-buf)
        buffer-window (vim.fn.bufwinid buffer)
        tracked-window (. output-windows source-buf)
        existing (if (and tracked-window
                          (vim.api.nvim_win_is_valid tracked-window))
                     tracked-window
                     buffer-window)]
    (if (and existing (>= existing 0) (vim.api.nvim_win_is_valid existing))
        (do
          (when (not= (vim.api.nvim_win_get_buf existing) buffer)
            (vim.api.nvim_win_set_buf existing buffer))
          (tset output-windows source-buf existing)
          (when focus?
            (vim.api.nvim_set_current_win existing))
          existing)
        (let [source-win (vim.api.nvim_get_current_win)]
          (vim.cmd "botright vsplit")
          (let [winid (vim.api.nvim_get_current_win)
                width (math.max 42
                                (math.floor (* vim.o.columns
                                               tlaplus.settings.output_width)))]
            (vim.api.nvim_win_set_buf winid buffer)
            (vim.api.nvim_win_set_width winid width)
            (tset output-windows source-buf winid)
            (when (and (not focus?) (vim.api.nvim_win_is_valid source-win))
              (vim.api.nvim_set_current_win source-win))
            winid)))))

(fn append-output [bufnr text]
  (when (and text (not= text ""))
    (let [current (or (. last-output bufnr) "")
          combined (.. current text)
          output-buffer (. output-buffers bufnr)]
      (tset last-output bufnr combined)
      (when output-buffer
        (vim.schedule (fn []
                        (render-output output-buffer combined)))))))

(fn reset-output [bufnr command]
  (let [header (.. "$ " (table.concat command " ") "\n\n")]
    (tset last-output bufnr header)
    (render-output (ensure-output-buffer bufnr) header)))

(fn location-from-line [line]
  (let [(lnum col) (string.match line "line%s+(%d+),%s+col%s+(%d+)")]
    (if lnum
        [(tonumber lnum) (tonumber col)]
        (let [(line-number column) (string.match line
                                                 "line%s+(%d+),%s+column%s+(%d+)")]
          (if line-number
              [(tonumber line-number) (tonumber column)]
              nil)))))

(fn error-line? [line]
  (let [lower (string.lower (or line ""))]
    (and (not (string.find lower "no error has been found" 1 true))
         (or (string.find lower :error 1 true)
             (string.find lower :encountered 1 true)
             (string.find lower :violat 1 true)
             (string.find lower :failed 1 true)
             (string.find lower :exception 1 true)
             (string.find lower :abort 1 true)))))

(fn nearby-error [lines index]
  (var found nil)
  (let [first (math.max 1 (- index 3))
        last (math.min (length lines) (+ index 3))]
    (for [candidate-index first last]
      (let [candidate (. lines candidate-index)]
        (when (and (not found) (error-line? candidate))
          (set found candidate)))))
  found)

(fn diagnostics-from-output [text]
  (local diagnostics [])
  (local quickfix [])
  (local seen {})
  (let [lines (vim.split text "\n" {:plain true})]
    (each [index line (ipairs lines)]
      (let [location (location-from-line line)
            message (if (error-line? line)
                        line
                        (nearby-error lines index))]
        (when (and location message)
          (let [lnum (. location 1)
                col (. location 2)
                key (.. lnum ":" col ":" line)]
            (when (not (. seen key))
              (tset seen key true)
              (table.insert diagnostics
                            {:lnum (math.max 0 (- lnum 1))
                             :col (math.max 0 (- col 1))
                             :severity vim.diagnostic.severity.ERROR
                             :source :TLA+
                             :message (vim.trim message)})
              (table.insert quickfix {: lnum : col :text (vim.trim message)})))))))
  [diagnostics quickfix])

(fn publish-diagnostics [bufnr text title]
  (when (vim.api.nvim_buf_is_valid bufnr)
    (let [[diagnostics quickfix] (diagnostics-from-output text)
          filename (vim.api.nvim_buf_get_name bufnr)]
      (vim.diagnostic.set diagnostic-namespace bufnr diagnostics
                          {:virtual_text true
                           :underline true
                           :severity_sort true})
      (let [items (vim.tbl_map (fn [item]
                                 (vim.tbl_extend :force {: filename} item))
                               quickfix)]
        (vim.fn.setqflist [] :r {: title : items})))))

(fn stop-task [bufnr mark-cancelled?]
  (let [process (. tasks bufnr)]
    (when process
      (when mark-cancelled?
        (tset cancelled process true))
      (pcall #(: process :kill 15))
      (tset tasks bufnr nil)
      (tset task-tokens bufnr nil))))

(fn cancel-current []
  (let [spec (current-spec true)
        bufnr (if spec (source-buffer spec) (vim.api.nvim_get_current_buf))]
    (if (. tasks bufnr)
        (do
          (stop-task bufnr true)
          (notify "已请求停止当前 TLA+ 任务" vim.log.levels.WARN))
        (notify "当前没有运行中的 TLA+ 任务"))))

(fn command-vector [subcommand spec extras]
  (local command [(tool-script) subcommand])
  (when spec
    (table.insert command spec))
  (each [_ arg (ipairs (or extras []))]
    (when (and arg (not= arg ""))
      (table.insert command arg)))
  command)

(fn run-tool [subcommand options]
  (when (ensure-tool-script)
    (let [spec options.spec
          bufnr (or options.bufnr (and spec (source-buffer spec))
                    (vim.api.nvim_get_current_buf))
          command (command-vector subcommand spec options.args)
          cwd (or options.cwd (and spec (align-tab-root spec)) (vim.fn.getcwd))
          show? (not= options.show false)
          token {}]
      (stop-task bufnr true)
      (tset task-tokens bufnr token)
      (reset-output bufnr command)
      (when show?
        (open-output bufnr false))
      (var process nil)
      (set process
           (vim.system command
                       {: cwd
                        :text true
                        :timeout options.timeout
                        :stdout (fn [_ data]
                                  (when (= (. task-tokens bufnr) token)
                                    (append-output bufnr data)))
                        :stderr (fn [_ data]
                                  (when (= (. task-tokens bufnr) token)
                                    (append-output bufnr data)))}
                       (fn [result]
                         (vim.schedule (fn []
                                         (when (= (. tasks bufnr) process)
                                           (tset tasks bufnr nil)
                                           (tset task-tokens bufnr nil))
                                         (let [text (or (. last-output bufnr)
                                                        "")
                                               was-cancelled (. cancelled
                                                                process)
                                               success (= result.code 0)]
                                           (tset cancelled process nil)
                                           (when (and options.diagnostics
                                                      (not was-cancelled))
                                             (publish-diagnostics bufnr text
                                                                  options.title))
                                           (when (and (not success)
                                                      options.open_on_error
                                                      (not was-cancelled))
                                             (open-output bufnr false))
                                           (if was-cancelled
                                               nil
                                               (if success
                                                   (do
                                                     (when options.on_success
                                                       (options.on_success text
                                                                           result))
                                                     (when (not options.quiet)
                                                       (notify (.. options.title
                                                                   " 完成"))))
                                                   (do
                                                     (when options.on_failure
                                                       (options.on_failure text
                                                                           result))
                                                     (notify (.. options.title
                                                                 " 失败（exit "
                                                                 result.code
                                                                 "）")
                                                             vim.log.levels.ERROR))))))))))
      (tset tasks bufnr process)
      process)))

(fn require-saved-spec []
  (let [current-buf (vim.api.nvim_get_current_buf)
        spec (current-spec false)]
    (if (not spec)
        nil
        (if (or (. (. vim.bo current-buf) :modified)
                (. (. vim.bo (source-buffer spec)) :modified))
            (do
              (notify "当前 TLA+ 文件或 TLC 配置有未保存修改；请先保存再运行验证"
                      vim.log.levels.WARN)
              nil)
            spec))))

(fn run-check [show?]
  (let [spec (require-saved-spec)]
    (when spec
      (run-tool :check {: spec
                        :show show?
                        :quiet (not show?)
                        :open_on_error true
                        :diagnostics true
                        :timeout tlaplus.settings.check_timeout_ms
                        :title "SANY 检查"}))))

(fn run-model-check [cfg]
  (let [spec (require-saved-spec)]
    (when spec
      (run-tool :model-check
                {: spec
                 :args (if (and cfg (not= cfg "")) [cfg] [])
                 :show true
                 :open_on_error true
                 :diagnostics true
                 :title "TLC 模型检查"}))))

(fn smoke-args [arguments spec]
  (if (= (length arguments) 0)
      [(string.gsub spec "%.tla$" :.cfg)
       (tostring tlaplus.settings.smoke_seconds)]
      (if (and (= (length arguments) 1) (string.match (. arguments 1) "^%d+$"))
          [(string.gsub spec "%.tla$" :.cfg) (. arguments 1)]
          arguments)))

(fn run-smoke [arguments]
  (let [spec (require-saved-spec)]
    (when spec
      (run-tool :smoke {: spec
                        :args (smoke-args arguments spec)
                        :show true
                        :open_on_error true
                        :diagnostics true
                        :title "TLC smoke test"}))))

(fn refresh-translated-buffer [bufnr]
  (when (vim.api.nvim_buf_is_valid bufnr)
    (vim.api.nvim_buf_call bufnr
                           (fn []
                             (vim.cmd :edit!)))))

(fn run-translate []
  (let [spec (require-saved-spec)]
    (when spec
      (let [bufnr (source-buffer spec)]
        (run-tool :translate
                  {: spec
                   :show true
                   :open_on_error true
                   :title "PlusCal 翻译"
                   :on_success (fn [_ _]
                                 (refresh-translated-buffer bufnr)
                                 (run-tool :check
                                           {: spec
                                            : bufnr
                                            :show false
                                            :quiet true
                                            :open_on_error true
                                            :diagnostics true
                                            :timeout tlaplus.settings.check_timeout_ms
                                            :title "SANY 翻译检查"}))})))))

(fn graph-path [text marker]
  (string.match text (.. marker "=([^\r\n]+)")))

(fn render-graph [source-buf path]
  (if (and vim.env.KITTY_WINDOW_ID (= (vim.fn.executable :kitty) 1)
           (= (vim.fn.filereadable path) 1))
      (let [source-win (vim.api.nvim_get_current_win)
            result-win (. output-windows source-buf)
            target-win (if (and result-win
                                (vim.api.nvim_win_is_valid result-win))
                           result-win
                           (open-output source-buf false))]
        (vim.api.nvim_set_current_win target-win)
        (vim.cmd :enew)
        (let [graph-buffer (vim.api.nvim_get_current_buf)
              job (vim.fn.jobstart [:kitty
                                    :+kitten
                                    :icat
                                    :--hold
                                    :--align
                                    :center
                                    path]
                                   {:term true})]
          (tset (. vim.bo graph-buffer) :bufhidden :wipe)
          (tset graph-windows source-buf target-win)
          (when (<= job 0)
            (notify "无法启动 Kitty 图形渲染" vim.log.levels.ERROR)))
        (when (vim.api.nvim_win_is_valid source-win)
          (vim.api.nvim_set_current_win source-win)))
      (let [(process err) (vim.ui.open path)]
        (if process
            (notify "已用外部查看器打开 TLA+ 状态图")
            (notify (.. "无法打开状态图：" err) vim.log.levels.ERROR)))))

(fn run-graph [cfg]
  (let [spec (require-saved-spec)]
    (when spec
      (let [bufnr (source-buffer spec)]
        (run-tool :graph
                  {: spec
                   :args (if (and cfg (not= cfg "")) [cfg] [])
                   :show true
                   :open_on_error true
                   :diagnostics true
                   :title "TLC 状态图"
                   :on_success (fn [text _]
                                 (let [image (or (graph-path text
                                                             :TLAPLUS_GRAPH_PNG)
                                                 (graph-path text
                                                             :TLAPLUS_GRAPH_SVG))]
                                   (if image
                                       (render-graph bufnr image)
                                       (notify "状态图已生成，但未找到输出路径"
                                               vim.log.levels.WARN))))})))))

(fn run-health []
  (run-tool :health {:bufnr (vim.api.nvim_get_current_buf)
                     :show true
                     :open_on_error true
                     :title "TLA+ 环境检查"}))

(fn run-install []
  (run-tool :install {:bufnr (vim.api.nvim_get_current_buf)
                      :show true
                      :open_on_error true
                      :title "TLA+ 工具安装"}))

(fn close-workbench []
  (let [spec (current-spec true)
        bufnr (if spec (source-buffer spec) (vim.api.nvim_get_current_buf))]
    (close-window (. graph-windows bufnr))
    (close-window (. output-windows bufnr))
    (tset graph-windows bufnr nil)
    (tset output-windows bufnr nil)))

(fn open-workbench []
  (let [spec (current-spec false)]
    (when spec
      (let [bufnr (source-buffer spec)
            existing (. last-output bufnr)]
        (align-tab-root spec)
        (when (not existing)
          (let [welcome (table.concat ["TLA+ Workbench"
                                       ""
                                       "  :TlaCheck             SANY syntax and level check"
                                       "  :TlaModelCheck [cfg]  exhaustive TLC model check"
                                       "  :TlaSmoke [cfg] [s]   bounded random simulation"
                                       "  :TlaTranslate         PlusCal translation"
                                       "  :TlaGraph [cfg]       reachable-state graph"
                                       "  :TlaCancel            stop the active task"
                                       ""
                                       "Run :TlaHealth first. TLC success means no counterexample"
                                       "was found in the configured finite model; it is not a proof."]
                                      "\n")]
            (tset last-output bufnr welcome)
            (render-output (ensure-output-buffer bufnr) welcome)))
        (open-output bufnr false)))))

(fn open-external-workspace []
  (let [spec (require-saved-spec)]
    (when spec
      (if vim.env.TLAPLUS_WORKBENCH
          (notify "当前已经在 TLA+ Kitty + Zellij 工作台中")
          (if (= (vim.fn.executable :kitty) 0)
              (notify "未找到 Kitty；请先安装 `brew install --cask kitty`"
                      vim.log.levels.ERROR)
              (if (= (vim.fn.executable :zellij) 0)
                  (notify "未找到 Zellij" vim.log.levels.ERROR)
                  (let [launcher (vim.fs.joinpath (vim.fn.stdpath :config)
                                                  :tools :tlaplus-workbench.sh)]
                    (if (= (vim.fn.executable launcher) 0)
                        (notify (.. "TLA+ 工作台启动脚本不可执行："
                                    launcher)
                                vim.log.levels.ERROR)
                        (vim.system [launcher spec] {:text true}
                                    (fn [result]
                                      (vim.schedule (fn []
                                                      (if (= result.code 0)
                                                          (notify "已打开 TLA+ Kitty + Zellij 工作台")
                                                          (notify (.. "启动 TLA+ 工作台失败："
                                                                      (vim.trim (or result.stderr
                                                                                    "")))
                                                                  vim.log.levels.ERROR))))))))))))))

(fn ensure-lazy-plugin [name]
  (let [packed [(pcall require :lazy)]
        ok (. packed 1)
        lazy (. packed 2)]
    (when ok
      (pcall #((. lazy :load) {:plugins [name]})))
    ok))

(fn ensure-agentic []
  (ensure-lazy-plugin :agentic.nvim)
  (let [packed [(pcall require :agentic)]
        ok (. packed 1)
        module (. packed 2)]
    (when (not ok)
      (notify (.. "Agentic 未加载；可以在 Zellij agent tab 中使用 TraeX："
                  module) vim.log.levels.ERROR))
    (if ok module nil)))

(fn with-agent-session [callback]
  (when (ensure-agentic)
    (let [packed [(pcall require :agentic.session_registry)]
          ok (. packed 1)
          registry (. packed 2)]
      (if ok
          ((. registry :get_session_for_tab_page) nil callback)
          (notify (.. "无法访问 Agentic session：" registry)
                  vim.log.levels.ERROR)))))

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

(fn capture-agent-selection []
  (let [mode (. (vim.api.nvim_get_mode) :mode)
        visual? (or (= mode :v) (= mode :V) (= mode "\022"))]
    (when visual?
      (let [packed [(pcall require :agentic.ui.code_selection)]
            ok (. packed 1)
            code-selection (. packed 2)]
        (when ok
          ((. code-selection :get_selected_text)))))))

(fn mode-instructions [mode]
  (match mode
    :explain ["解释当前 operator、状态变量、Init/Next 关系和性质。"
              "不要修改文件。"]
    :model
    ["检查或设计有限 TLC 模型配置，说明常量、对称集和状态空间边界。"
     "不要把抽样或有限模型结论表述为一般性证明。"]
    _ ["分析最近的 SANY/TLC 输出或 counterexample。"
       "定位第一个错误状态与导致它的 action，提出最小修复。"
       "修改后必须重新运行 SANY 和 TLC；不得仅凭推理宣称验证通过。"]))

(fn normalize-agent-mode [requested]
  (let [mode (string.lower (or requested ""))]
    (if (vim.tbl_contains [:explain :model :debug] mode)
        mode
        tlaplus.settings.agent_default_mode)))

(fn compact-output [text]
  (let [limit 12000
        value (or text "（尚未运行 SANY/TLC）")]
    (if (> (string.len value) limit)
        (.. "…（已截断前部）\n" (string.sub value (- limit)))
        value)))

(fn ask-agent [requested-mode]
  (let [mode (normalize-agent-mode requested-mode)
        spec (current-spec false)]
    (when spec
      (let [bufnr (source-buffer spec)
            position (vim.api.nvim_win_get_cursor 0)
            selection (capture-agent-selection)
            cfg (string.gsub spec "%.tla$" :.cfg)
            instructions (vim.tbl_map (fn [line] (.. "- " line))
                                      (mode-instructions mode))
            prompt-lines ["请协助处理当前 TLA+ / PlusCal 规格。"
                          ""
                          (.. "文件：" (vim.fn.fnamemodify spec ":."))
                          (.. "TLC 配置：" (vim.fn.fnamemodify cfg ":."))
                          (string.format "位置：%d:%d" (. position 1)
                                         (+ (. position 2) 1))
                          ""
                          "要求："]]
        (align-tab-root spec)
        (vim.list_extend prompt-lines instructions)
        (vim.list_extend prompt-lines
                         ["- 先读取规格、配置、诊断和下面的工具输出，再给出结论。"
                          "- 必须区分：语法/level check、有限模型未发现反例、形式化证明。"
                          "- 不要伪造 TLC、SANY、TLAPS 或 Apalache 的运行结果。"
                          ""
                          "最近的工具输出："
                          ""
                          "```text"
                          (compact-output (. last-output bufnr))
                          "```"])
        (with-agent-session (fn [session]
                              (when selection
                                (: session.code_selection :add selection))
                              (: session :add_file_to_session bufnr)
                              (: session
                                 :add_current_line_diagnostics_to_context bufnr)
                              (append-agent-prompt session
                                                   (table.concat prompt-lines
                                                                 "\n"))))))))

(fn map-buffer [bufnr]
  (local map (fn [mode lhs rhs desc]
               (vim.keymap.set mode lhs rhs
                               {:buffer bufnr
                                :silent true
                                :noremap true
                                : desc})))
  (map :n ",c" #(run-check true) "TLA+: SANY check")
  (map :n ",m" #(run-model-check nil) "TLA+: TLC model check")
  (map :n ",s" #(run-smoke []) "TLA+: TLC smoke test")
  (map :n ",t" run-translate "TLA+: Translate PlusCal")
  (map :n ",g" #(run-graph nil) "TLA+: Render state graph")
  (map :n ",x" cancel-current "TLA+: Cancel active task")
  (map :n ",w" open-workbench "TLA+: Open result workbench")
  (map :n ",q" close-workbench "TLA+: Close result workbench")
  (map :n ",a" #(ask-agent :debug) "TLA+: Ask TraeX")
  (map :x ",a" #(ask-agent :debug) "TLA+: Ask TraeX about selection")
  (map :n ",h" run-health "TLA+: Toolchain health")
  (map :n ",o" open-external-workspace "TLA+: Open Kitty workspace"))

(fn initialize-tla-buffer [bufnr]
  (when (not (. (. vim.b bufnr) :tlaplus_gentlewind_initialized))
    (tset (. vim.b bufnr) :tlaplus_gentlewind_initialized true)
    (tset (. vim.bo bufnr) :commentstring "\\* %s")
    (map-buffer bufnr)))

(fn check-on-save [args]
  (when (and tlaplus.settings.check_on_save (toolchain-ready?)
             (vim.api.nvim_buf_is_valid args.buf) (not (. tasks args.buf)))
    (let [spec (vim.api.nvim_buf_get_name args.buf)]
      (run-tool :check {: spec
                        :bufnr args.buf
                        :show false
                        :quiet true
                        :open_on_error true
                        :diagnostics true
                        :timeout tlaplus.settings.check_timeout_ms
                        :title "SANY 保存检查"}))))

(fn stop-all-tasks []
  (each [bufnr _ (pairs tasks)]
    (stop-task bufnr false)))

(set tlaplus.packages {})
(set tlaplus.configs {})
(set tlaplus.autocmds
     [{:BufReadPost :*.cfg
       :callback (fn [args] (detect-cfg-filetype args.buf))}
      {:BufNewFile :*.cfg :callback (fn [args] (detect-cfg-filetype args.buf))}
      {:FileType [:tlaplus :tlaplusconfig]
       :callback (fn [args]
                   (initialize-tla-buffer args.buf)
                   (when (not tlaplus.settings.disable_treesitter)
                     (langs-utils.use_tree_sitter tlaplus.settings.treesitter_grammars)))}
      {:BufWritePost :*.tla :callback check-on-save}
      {:VimLeavePre "*" :callback stop-all-tasks}])

(set tlaplus.cmds
     [[:TlaInstall run-install {:desc "Install the pinned TLA+ tools release"}]
      [:TlaHealth run-health {:desc "Check Java, tla2tools.jar and Graphviz"}]
      [:TlaCheck
       (fn [] (run-check true))
       {:desc "Run SANY syntax, semantic and level checking"}]
      [:TlaModelCheck
       (fn [opts] (run-model-check opts.args))
       {:nargs "?" :complete :file :desc "Run exhaustive TLC model checking"}]
      [:TlaSmoke
       (fn [opts] (run-smoke opts.fargs))
       {:nargs "*"
        :complete :file
        :desc "Run bounded-time TLC random simulation"}]
      [:TlaTranslate run-translate {:desc "Translate PlusCal to TLA+"}]
      [:TlaGraph
       (fn [opts] (run-graph opts.args))
       {:nargs "?"
        :complete :file
        :desc "Generate and render the TLC state graph"}]
      [:TlaCancel cancel-current {:desc "Stop the active TLA+ task"}]
      [:TlaWorkbenchOpen
       open-workbench
       {:desc "Open the TLA+ source and result workspace"}]
      [:TlaWorkbenchClose
       close-workbench
       {:desc "Close the TLA+ result workspace"}]
      [:TlaWorkspace
       open-external-workspace
       {:desc "Open the Kitty and Zellij TLA+ workspace"}]
      [:TlaAgentAsk
       (fn [opts] (ask-agent opts.args))
       {:nargs "?"
        :complete (fn [] [:explain :model :debug])
        :desc "Ask TraeX about the current TLA+ specification"}]
      [:TlaAgentExplain
       #(ask-agent :explain)
       {:desc "Ask TraeX to explain the current TLA+ specification"}]
      [:TlaAgentModel
       #(ask-agent :model)
       {:desc "Ask TraeX to design or review a TLC model"}]
      [:TlaAgentDebug
       #(ask-agent :debug)
       {:desc "Ask TraeX to analyze the latest verification output"}]])

(set tlaplus.binds [])

{:packages tlaplus.packages
 :configs tlaplus.configs
 :settings tlaplus.settings
 :autocmds tlaplus.autocmds
 :cmds tlaplus.cmds
 :binds tlaplus.binds}

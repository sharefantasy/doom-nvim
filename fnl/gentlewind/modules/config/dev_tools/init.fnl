;; user.modules.config.dev_tools
(local M {})

;; =============================
;; Hydra 子模态（Git / Debug / Hurl）
;; =============================

(var _git_hydra nil)
(var _debug_hydra nil)
(var _hurl_hydra nil)
(var _kulala_hydra nil)
(var _neotest_hydra nil)
(var _kulala_history_path nil)
(var _conflict_hydra nil)
(var _agentic_hydra nil)
(var _jj_hydra nil)
(fn notify-missing [what]
  (vim.notify (.. "未启用/未安装：" what) vim.log.levels.WARN))

(fn safe-require [mod]
  (let [packed [(pcall require mod)]
        ok (. packed 1)
        res (. packed 2)]
    (if ok res nil)))

(fn ensure-plugin [name]
  (let [packed [(pcall require :lazy)]
        ok (. packed 1)
        lazy (. packed 2)]
    (when ok
      (pcall (fn [] ((. lazy :load) {:plugins [name]}))))))

(fn kulala-history-path []
  (when (not _kulala_history_path)
    (local dir (vim.fs.joinpath (vim.fn.stdpath "state") "kulala"))
    (pcall vim.fn.mkdir dir "p")
    (set _kulala_history_path (vim.fs.joinpath dir "history.jsonl")))
  _kulala_history_path)

(fn append-jsonl! [path tbl]
  (let [line (vim.json.encode tbl)]
    (pcall vim.fn.writefile [line] path "a")))

(fn kulala-log-last! [action]
  ;; 方案 A：最小可用的“访问历史”——先记录执行时间/来源 file/ft/光标位置；
  ;; 后续再迭代：解析请求块（method/url/headers/body/env）。
  (let [file (vim.api.nvim_buf_get_name 0)
        ft vim.bo.filetype
        pos (vim.api.nvim_win_get_cursor 0)
        row (. pos 1)
        col (. pos 2)]
    (append-jsonl!
      (kulala-history-path)
      {:ts (os.time)
       :action action
       :file file
       :ft ft
       :row row
       :col col})))

(fn kulala-open-history []
  ;; 简易查看：优先用 Telescope 打开 history.jsonl（后续可升级为 picker + replay）
  (let [p (kulala-history-path)
        packed [(pcall require :telescope.builtin)]
        ok (. packed 1)
        tb (. packed 2)]
    (if ok
        ((. tb :find_files) {:search_file p :cwd (vim.fs.dirname p) :hidden true})
        (pcall vim.cmd (.. "edit " (vim.fn.fnameescape p))))))

;; conflict view: "conflux" | "diffview"
(fn get-conflict-view []
  (or vim.g.gentlewind_conflict_view "conflux"))

(fn set-conflict-view [v]
  (set vim.g.gentlewind_conflict_view v))

(fn ensure-diffview-actions []
  ;; diffview 可能尚未加载：先尝试打开一次 DiffviewOpen 触发 lazy 加载。
  (let [actions (safe-require :diffview.actions)]
    (if actions
        actions
        (do
          (pcall vim.cmd "DiffviewOpen")
          (safe-require :diffview.actions)))))

(fn diffview-open []
  (pcall vim.cmd "DiffviewOpen"))

(fn diffview-close []
  (pcall vim.cmd "DiffviewClose"))

(fn diffview-focus-files []
  (pcall vim.cmd "DiffviewFocusFiles"))

(fn diffview-refresh []
  (pcall vim.cmd "DiffviewRefresh"))

(fn conflict-choose [scope choice]
  ;; scope: :block | :all
  (case (get-conflict-view)
    "diffview"
    (let [actions (ensure-diffview-actions)]
      (if (not actions)
          (notify-missing "sindrets/diffview.nvim")
          (pcall (fn []
                   (if (= scope :all)
                       (((. actions :conflict_choose_all) choice))
                       (((. actions :conflict_choose) choice)))))))

    _
    (pcall (fn []
             (case scope
               :all
               (case choice
                 "ours" (vim.cmd "ConfluxAllOurs")
                 "theirs" (vim.cmd "ConfluxAllTheirs")
                 "all" (vim.cmd "ConfluxAllBoth")
                 "none" (vim.cmd "ConfluxAllNone")
                 _ nil)
               :block
               (case choice
                 "ours" (vim.cmd "ConfluxOurs")
                 "theirs" (vim.cmd "ConfluxTheirs")
                 "all" (vim.cmd "ConfluxBoth")
                 "none" (vim.cmd "ConfluxNone")
                 _ nil)
               _ nil)))))

(fn conflict-next []
  (case (get-conflict-view)
    "diffview"
    (let [actions (ensure-diffview-actions)]
      (if (not actions)
          (notify-missing "sindrets/diffview.nvim")
          (pcall (fn [] ((. actions :next_conflict))))))
    _
    (pcall vim.cmd "ConfluxNext")))

(fn conflict-prev []
  (case (get-conflict-view)
    "diffview"
    (let [actions (ensure-diffview-actions)]
      (if (not actions)
          (notify-missing "sindrets/diffview.nvim")
          (pcall (fn [] ((. actions :prev_conflict))))))
    _
    (pcall vim.cmd "ConfluxPrev")))

(fn conflict-list []
  (case (get-conflict-view)
    "diffview" (do
                  ;; 优先聚焦文件面板；若 diffview 尚未打开则再打开。
                  (when (not (pcall diffview-focus-files))
                    (diffview-open)
                    (diffview-focus-files)))
    _ (pcall vim.cmd "ConfluxQuickfix")))

(fn ensure-git-hydra []
  (when (not _git_hydra)
    (local Hydra (safe-require :hydra))
    (if (not Hydra)
        (notify-missing "anuvyklack/hydra.nvim")
        (let [hint (table.concat
                     [" Git"
                      ""
                      " _J_: next hunk    _K_: prev hunk"
                      " _s_: stage hunk   _u_: undo stage   _S_: stage buffer"
                      " _p_: preview      _d_: deleted      _b_: blame   _B_: blame(full)"
                      " _t_: git status   _<Enter>_: neogit"
                      ""
                      " _q_: quit"]
                     "\n")]
          (set _git_hydra
               (Hydra
                 {:name "Git"
                  :mode ["n" "x"]
                  :hint hint
                  ;; NOTE: nvim 0.12 下，hydra.nvim 的 "pink" 会走 Layer 路径，
                  ;; Layer 内部对 getfenv()/vim.* 的兼容处理会触发 `vim.startswith` 参数校验错误。
                  ;; 这里改成 teal，规避 Layer 逻辑（方案 A）。
                  :config {:color "teal"
                           :invoke_on_body true
                           :hint {:border "rounded" :position "middle"}}
                  :heads
                  [["J"
                    (fn []
                      (if vim.wo.diff
                          "]c"
                          (do
                            (local gs (safe-require :gitsigns))
                            (if gs
                                (do
                                  (vim.schedule gs.next_hunk)
                                  "")
                                (do (notify-missing "lewis6991/gitsigns.nvim") "")))))
                    {:expr true :desc "Next hunk"}]

                   ["K"
                    (fn []
                      (if vim.wo.diff
                          "[c"
                          (do
                            (local gs (safe-require :gitsigns))
                            (if gs
                                (do
                                  (vim.schedule gs.prev_hunk)
                                  "")
                                (do (notify-missing "lewis6991/gitsigns.nvim") "")))))
                    {:expr true :desc "Prev hunk"}]

                   ["s" (fn [] (pcall vim.cmd "Gitsigns stage_hunk")) {:desc "Stage hunk"}]
                   ["u" (fn []
                          (local gs (safe-require :gitsigns))
                          (if gs
                              (gs.undo_stage_hunk)
                              (notify-missing "lewis6991/gitsigns.nvim")))
                    {:desc "Undo stage"}]
                   ["S" (fn []
                          (local gs (safe-require :gitsigns))
                          (if gs
                              (gs.stage_buffer)
                              (notify-missing "lewis6991/gitsigns.nvim")))
                    {:desc "Stage buffer"}]
                   ["p" (fn []
                          (local gs (safe-require :gitsigns))
                          (if gs
                              (gs.preview_hunk)
                              (notify-missing "lewis6991/gitsigns.nvim")))
                    {:desc "Preview"}]
                   ["d" (fn []
                          (local gs (safe-require :gitsigns))
                          (if gs
                              (gs.toggle_deleted)
                              (notify-missing "lewis6991/gitsigns.nvim")))
                    {:desc "Toggle deleted" :nowait true}]
                   ["b" (fn []
                          (local gs (safe-require :gitsigns))
                          (if gs
                              (gs.blame_line)
                              (notify-missing "lewis6991/gitsigns.nvim")))
                    {:desc "Blame"}]
                   ["B" (fn []
                          (local gs (safe-require :gitsigns))
                          (if gs
                              (gs.blame_line {:full true})
                              (notify-missing "lewis6991/gitsigns.nvim")))
                    {:desc "Blame (full)"}]

                   ["t" (fn []
                          (pcall (fn []
                                   (local Snacks (require :snacks))
                                   ((. (. Snacks :picker) :git_status)))))
                    {:exit true :desc "Git status"}]
                   ["<Enter>" (fn [] (pcall vim.cmd "Neogit")) {:exit true :desc "Neogit"}]
                   ["q" nil {:exit true :nowait true :desc "Quit"}]]})))))
  _git_hydra)

(fn ensure-conflict-hydra []
  (when (not _conflict_hydra)
    (local Hydra (safe-require :hydra))
    (if (not Hydra)
        (notify-missing "anuvyklack/hydra.nvim")
        (let [hint (table.concat
                     [" Git Conflict"
                      ""
                      " Block:  _o_ ours   _t_ theirs   _b_ both   _n_ none"
                     "  All :  _O_ ours   _T_ theirs   _B_ both   _N_ none"
                     "  Nav :  _j_ next   _k_ prev     _v_ view   _q_ quit"
                     ""
                     " <leader>g c q  Quickfix"]
                     "\n")]
          (set _conflict_hydra
               (Hydra
                 {:name "Git Conflict"
                  :mode "n"
                  :hint hint
                  :config {:color "amaranth"
                           :invoke_on_body true
                           :hint {:border "rounded" :position "bottom"}}
                  :heads
                  [["o" (fn [] (conflict-choose :block "ours")) {:desc "Ours"}]
                   ["t" (fn [] (conflict-choose :block "theirs")) {:desc "Theirs"}]
                   ["b" (fn [] (conflict-choose :block "all")) {:desc "Both"}]
                   ["n" (fn [] (conflict-choose :block "none")) {:desc "None"}]

                   ["O" (fn [] (conflict-choose :all "ours")) {:desc "All ours"}]
                   ["T" (fn [] (conflict-choose :all "theirs")) {:desc "All theirs"}]
                   ["B" (fn [] (conflict-choose :all "all")) {:desc "All both"}]
                   ["N" (fn [] (conflict-choose :all "none")) {:desc "All none"}]

                   ["j" (fn [] (conflict-next)) {:desc "Next"}]
                   ["k" (fn [] (conflict-prev)) {:desc "Prev"}]
                   ["v"
                    (fn []
                      (if (= (get-conflict-view) "conflux")
                          (do
                            (set-conflict-view "diffview")
                            (diffview-open)
                            (diffview-focus-files)
                            (vim.notify "Conflict 视图：diffview"))
                          (do
                            (set-conflict-view "conflux")
                            (diffview-close)
                            (vim.notify "Conflict 视图：conflux"))))
                    {:desc "Toggle view" :nowait true}]
                   ["q" nil {:exit true :nowait true :desc "Quit"}]]})))))
  _conflict_hydra)

(fn ensure-debug-hydra []
  (when (not _debug_hydra)
    (local Hydra (safe-require :hydra))
    (if (not Hydra)
        (notify-missing "anuvyklack/hydra.nvim")
        (let [hint (table.concat
                     [" Debug (debugmaster)"
                      ""
                      " _c_: continue/start   _o_: step over   _m_: step into   _q_: step out"
                      " _r_: run to cursor    _t_: toggle bp"
                      " _u_: sidebar          _U_: float UI     _H_: help"
                      " _d_: exit debug mode  _<Esc>_: hide hint"
                      ""
                      "（提示层：其他键会透传给 debugmaster，不会退出）"]
                     "\n")
              feed (fn [k]
                     (vim.api.nvim_feedkeys
                       (vim.api.nvim_replace_termcodes k true false true)
                       "n"
                       false))]
          (set _debug_hydra
               (Hydra
                 {:name "Debug"
                  :mode "n"
                  :hint hint
                  :config {:color "amaranth"
                           :invoke_on_body true
                           :timeout 5000
                           :foreign_keys "run"
                           :hint {:border "rounded" :position "bottom"}}
                  :heads [["c" (fn [] (feed "c")) {:desc "continue/start"}]
                          ["o" (fn [] (feed "o")) {:desc "step over"}]
                          ["m" (fn [] (feed "m")) {:desc "step into"}]
                          ["q" (fn [] (feed "q")) {:desc "step out"}]
                          ["r" (fn [] (feed "r")) {:desc "run to cursor"}]
                          ["t" (fn [] (feed "t")) {:desc "toggle breakpoint"}]
                          ["u" (fn [] (feed "u")) {:desc "toggle sidebar"}]
                          ["U" (fn [] (feed "U")) {:desc "toggle float UI"}]
                          ["H" (fn [] (feed "H")) {:desc "help"}]
                          ["d" (fn [] (feed "d")) {:exit true :nowait true :desc "exit debug mode"}]
                          ["<Esc>" nil {:exit true :nowait true :desc "hide"}]]})))))
  _debug_hydra)

(fn ensure-hurl-hydra []
  (when (not _hurl_hydra)
    (local Hydra (safe-require :hydra))
    (if (not Hydra)
        (notify-missing "anuvyklack/hydra.nvim")
        (let [cmd (fn [ex]
                    (ensure-plugin "hurl.nvim")
                    (pcall vim.cmd ex))
              hint (table.concat
                     [" Hurl"
                      ""
                      " _e_: run entry"
                      " _r_: run (range/selection if exists)"
                      " _m_: mode     _v_: verbose"
                      ""
                      " _q_: quit"]
                     "\n")]
          (set _hurl_hydra
               (Hydra
                 {:name "Hurl"
                  :mode ["n" "x"]
                  :hint hint
                  :config {:color "teal"
                           :invoke_on_body true
                           :hint {:border "rounded" :position "middle"}}
                  :heads
                  [["e" (fn [] (cmd "HurlRunnerToEntry")) {:desc "Run entry"}]
                   ["r" (fn []
                          ;; 先尝试用最近一次 visual 选区（'<,'>），失败再 fallback 到普通 HurlRunner。
                          (if (not (cmd "'<,'>HurlRunner"))
                              (cmd "HurlRunner")))
                    {:desc "Run"}]
                   ["m" (fn [] (cmd "HurlToggleMode")) {:desc "Toggle mode"}]
                   ["v" (fn [] (cmd "HurlVerbose")) {:desc "Verbose"}]
                   ["q" nil {:exit true :nowait true :desc "Quit"}]]})))))
  _hurl_hydra)

(fn ensure-kulala-hydra []
  (when (not _kulala_hydra)
    (local Hydra (safe-require :hydra))
    (if (not Hydra)
        (notify-missing "anuvyklack/hydra.nvim")
        (let [hint (table.concat
                     [" HTTP (Kulala)"
                      ""
                      " _r_: run    _a_: run all    _e_: pick request"
                      " _o_: open UI   _b_: scratch   _c_: copy as curl"
                      " _v_: toggle view   _E_: env"
                      " _f_: focus response   _j_: cookie jar   _W_: toggle write_cookies"
                      ""
                      " _q_: quit"]
                     "\n")

              kulala-focus-ui
              (fn []
                (ensure-plugin "kulala.nvim")
                (let [Globals (safe-require :kulala.globals)
                      ui-id (if Globals (. Globals :UI_ID) "kulala://ui")
                      buf (vim.fn.bufnr ui-id)]
                  (if (<= buf 0)
                      (vim.notify "Kulala UI 尚未打开（先运行/打开 UI）" vim.log.levels.WARN)
                      (let [win (. (vim.fn.win_findbuf buf) 1)]
                        (if (and win (> win 0))
                            (pcall (fn [] (vim.api.nvim_set_current_win win)))
                            (vim.notify "找不到 Kulala UI 窗口" vim.log.levels.WARN))))))

              with-kulala
              (fn [f]
                (ensure-plugin "kulala.nvim")
                (let [packed [(pcall require :kulala)]
                      ok (. packed 1)
                      kulala (. packed 2)]
                  (if ok
                      (do
                        ;; 关键：
                        ;; 1) 强制 split 模式，避免误触 `|` 切到 float（float 默认不可聚焦）
                        ;; 2) 默认总是读取 cookie jar（curl --cookie），支持粘贴链接也带 cookie
                        ;; 3) 默认不写 cookie jar（避免一次无 Set-Cookie 的响应把 jar 清空）
                        (let [Globals (safe-require :kulala.globals)
                              jar (and Globals (. Globals :COOKIES_JAR_FILE))]
                          (pcall
                            (fn []
                              ((. kulala :setup)
                               {:write_cookies false
                                :additional_curl_options (if jar ["--cookie" jar] [])
                                :ui {:display_mode "split"
                                     :split_direction "vertical"
                                     :win_opts {:wo {:wrap true :spell false}}}
                                ;; 禁用切换 split/float（避免再次进入不可聚焦状态）
                                :kulala_keymaps {"Toggle split/float" false}}))))
                        (pcall (fn [] (f kulala))))
                      (notify-missing "mistweaverco/kulala.nvim"))))

              kulala-toggle-write-cookies
              (fn []
                (ensure-plugin "kulala.nvim")
                (let [Config (safe-require :kulala.config)]
                  (if (not Config)
                      (notify-missing "mistweaverco/kulala.nvim")
                      (let [curr (. (. Config :options) :write_cookies)
                            nextv (not curr)]
                        ((. Config :set) {:write_cookies nextv})
                        (vim.notify (.. "Kulala write_cookies: " (if nextv "ON" "OFF")) vim.log.levels.INFO)))))]

          (set _kulala_hydra
               (Hydra
                 {:name "Kulala"
                  :mode ["n" "x"]
                  :hint hint
                  :config {:color "teal"
                           :invoke_on_body true
                           :hint {:border "rounded" :position "middle"}}
                  :heads
                  [["r" (fn [] (kulala-log-last! "run") (with-kulala (fn [m] ((. m :run)) (kulala-focus-ui)))) {:desc "Run"}]
                   ["a" (fn [] (kulala-log-last! "run_all") (with-kulala (fn [m] ((. m :run_all)) (kulala-focus-ui)))) {:desc "Run all"}]
                   ["e" (fn [] (with-kulala (fn [m] ((. m :search))))) {:desc "Pick request"}]
                   ["o" (fn [] (kulala-log-last! "open") (with-kulala (fn [m] ((. m :open)) (kulala-focus-ui)))) {:desc "Open UI"}]
                   ["b" (fn [] (with-kulala (fn [m] ((. m :scratchpad))))) {:desc "Scratch"}]
                   ["c" (fn [] (with-kulala (fn [m] ((. m :copy))))) {:desc "Copy as cURL"}]
                   ["v" (fn [] (with-kulala (fn [m] ((. m :toggle_view))))) {:desc "Toggle view"}]
                   ["E" (fn [] (with-kulala (fn [m] ((. m :set_selected_env))))) {:desc "Select env"}]
                   ["f" (fn [] (kulala-focus-ui)) {:desc "Focus response"}]
                   ["j" (fn [] (with-kulala (fn [m] ((. m :open_cookies_jar)) (kulala-focus-ui)))) {:desc "Cookie jar"}]
                   ["W" (fn [] (kulala-toggle-write-cookies)) {:desc "Toggle write_cookies"}]
                   ["h" (fn [] (kulala-open-history)) {:desc "History"}]
                   ["q" nil {:exit true :nowait true :desc "Quit"}]]})))))
  _kulala_hydra)

(fn ensure-neotest-hydra []
  (when (not _neotest_hydra)
    (local Hydra (safe-require :hydra))
    (if (not Hydra)
        (notify-missing "anuvyklack/hydra.nvim")
        (let [hint (table.concat
                     [" Tests (Neotest)"
                      ""
                      " _r_: run nearest   _f_: run file   _p_: run project"
                      " _d_: debug nearest _s_: summary    _o_: output"
                      " _x_: stop"
                      ""
                      " _q_: quit"]
                     "\n")
              with-neotest
              (fn [f]
                (ensure-plugin "neotest")
                (let [packed [(pcall require :neotest)]
                      ok (. packed 1)
                      nt (. packed 2)]
                  (if ok
                      (pcall (fn [] (f nt)))
                      (notify-missing "nvim-neotest/neotest"))))]
          (set _neotest_hydra
               (Hydra
                 {:name "Neotest"
                  :mode ["n" "x"]
                  :hint hint
                  :config {:color "teal"
                           :invoke_on_body true
                           :hint {:border "rounded" :position "middle"}}
                  :heads
                  [["r" (fn [] (with-neotest (fn [nt] ((. (. nt :run) :run))))) {:desc "Run nearest"}]
                   ["f" (fn [] (with-neotest (fn [nt] ((. (. nt :run) :run) (vim.fn.expand "%"))))) {:desc "Run file"}]
                   ["p" (fn [] (with-neotest (fn [nt] ((. (. nt :run) :run) {:suite true})))) {:desc "Run project"}]
                   ["d" (fn [] (with-neotest (fn [nt] ((. (. nt :run) :run) {:strategy "dap"})))) {:desc "Debug nearest"}]
                   ["s" (fn [] (with-neotest (fn [nt] ((. (. nt :summary) :toggle))))) {:desc "Summary"}]
                   ["o" (fn [] (with-neotest (fn [nt] ((. (. nt :output) :open) {:enter true :auto_close true})))) {:desc "Output"}]
                   ["x" (fn [] (with-neotest (fn [nt] ((. (. nt :run) :stop))))) {:desc "Stop"}]
                   ["q" nil {:exit true :nowait true :desc "Quit"}]]})))))
  _neotest_hydra)

;; Agentic.nvim（ACP / TraeX）
(fn ensure-agentic-hydra []
  (when (not _agentic_hydra)
    (local Hydra (safe-require :hydra))
    (if (not Hydra)
        (notify-missing "anuvyklack/hydra.nvim")
        (let [Agentic (safe-require :agentic)
              SessionRegistry (safe-require :agentic.session_registry)]
          (if (or (not Agentic) (not SessionRegistry))
              (notify-missing "carlos-algms/agentic.nvim")
              (let [hint (table.concat
                           [" Agentic (TRAE CLI)"
                            ""
                            " _o_: toggle chat     _n_: new session    _r_: restore session"
                            " _x_: stop generation"
                            ""
                            " _a_: add selection/file   _f_: add file   _s_: add selection"
                            " _d_: diag(line)          _D_: diag(buffer)"
                            ""
                            " _m_: model   _M_: mode    _l_: rotate layout"
                            ""
                            " _q_: quit"
                            ""
                            "（提示：provider 已固定为 traex；Skills/MCP 统一从 ~/.trae/traecli.toml 加载）"]
                           "\n")
                    with-session
                    (fn [f]
                      ((. SessionRegistry :get_session_for_tab_page)
                       nil
                       (fn [session]
                         (when session (f session)))))
                    show-model
                    (fn []
                      (with-session
                        (fn [session]
                          (let [cfg (. session :config_options)]
                            (when cfg
                              (: cfg :show_model_selector
                                 (fn [model-id is-legacy]
                                   (: session :_handle_model_change model-id is-legacy))))))))
                    show-mode
                    (fn []
                      (with-session
                        (fn [session]
                          (let [cfg (. session :config_options)]
                            (when cfg
                              (: cfg :show_mode_selector
                                 (fn [mode-id is-legacy]
                                   (: session :_handle_mode_change mode-id is-legacy))))))))]
                (set _agentic_hydra
                     (Hydra
                       {:name "Agentic"
                        :mode ["n" "x"]
                        :hint hint
                        :config {:color "teal"
                                 :invoke_on_body true
                                 :hint {:border "rounded" :position "middle"}}
                        :heads
                        [["o" (fn [] ((. Agentic :toggle))) {:desc "Toggle chat"}]
                         ["n" (fn [] ((. Agentic :new_session))) {:exit true :desc "New session"}]
                         ["r" (fn [] ((. Agentic :restore_session))) {:exit true :desc "Restore session"}]
                         ["x" (fn [] ((. Agentic :stop_generation))) {:desc "Stop generation" :nowait true}]

                         ["a" (fn [] ((. Agentic :add_selection_or_file_to_context))) {:desc "Add sel/file"}]
                         ["f" (fn [] ((. Agentic :add_file))) {:exit true :desc "Add file"}]
                         ["s" (fn [] ((. Agentic :add_selection))) {:exit true :desc "Add selection"}]
                         ["d" (fn [] ((. Agentic :add_current_line_diagnostics))) {:exit true :desc "Diagnostics (line)"}]
                         ["D" (fn [] ((. Agentic :add_buffer_diagnostics))) {:exit true :desc "Diagnostics (buffer)"}]

                         ["m" show-model {:exit true :desc "Select model"}]
                         ["M" show-mode {:exit true :desc "Select mode"}]
                         ["l" (fn [] ((. Agentic :rotate_layout) ["right" "bottom" "left"])) {:desc "Rotate layout"}]

                         ["q" nil {:exit true :nowait true :desc "Quit"}]]})))))))
  _agentic_hydra)

;; =============================
;; JJ (Jujutsu) Hydra
;; =============================

(fn ensure-jj-hydra []
  (when (not _jj_hydra)
    ;; 前置检查：jj CLI 是否可用
    (when (= 0 (vim.fn.executable "jj"))
      (local Hydra (safe-require :hydra))
      (if (not Hydra)
          (notify-missing "anuvyklack/hydra.nvim")
          (let [hint (table.concat
                       [" JJ (Jujutsu)"
                        ""
                        " _l_: log          _s_: status       _d_: describe      _: commit"
                        " _n_: new          _e_: edit"
                        " _S_: squash       _r_: rebase       _a_: abandon"
                        " _u_: undo         _U_: redo"
                        " _f_: fetch        _p_: push         _P_: open PR"
                        " _b_: bookmark     _t_: tag"
                        " _v_: vdiff        _V_: hdiff"
                        " _o_: annot(file)  _O_: annot(line)"
                        " _ps_: pick(stat)  _ph_: pick(hist)"
                        ""
                        " _q_: quit"]
                       "\n")
                ;; 安全调用 jj 模块的包装器
                jj-cmd
                (fn [f]
                  (let [packed [(pcall require :jj.cmd)]
                        ok (. packed 1)
                        cmd (. packed 2)]
                    (if ok
                        (do (f cmd) "")
                        (do (notify-missing "NicolasGB/jj.nvim") ""))))

                jj-diff
                (fn [f]
                  (let [packed [(pcall require :jj.diff)]
                        ok (. packed 1)
                        diff (. packed 2)]
                    (if ok
                        (do (f diff) "")
                        (do (notify-missing "NicolasGB/jj.nvim") ""))))

                jj-annotate
                (fn [f]
                  (let [packed [(pcall require :jj.annotate)]
                        ok (. packed 1)
                        annotate (. packed 2)]
                    (if ok
                        (do (f annotate) "")
                        (do (notify-missing "NicolasGB/jj.nvim") ""))))

                jj-picker
                (fn [f]
                  (let [packed [(pcall require :jj.picker)]
                        ok (. packed 1)
                        picker (. packed 2)]
                    (if ok
                        (do (f picker) "")
                        (do (notify-missing "NicolasGB/jj.nvim") ""))))]
            (set _jj_hydra
                 (Hydra
                   {:name "JJ"
                    :mode ["n" "x"]
                    :hint hint
                    :config {:color "teal"
                             :invoke_on_body true
                             :hint {:border "rounded" :position "middle"}}
                    :heads
                    [["l" (fn [] (jj-cmd (fn [c] ((. c :log))))) {:exit true :desc "Log"}]

                     ["s" (fn [] (jj-cmd (fn [c] ((. c :status))))) {:exit true :desc "Status"}]

                     ["d" (fn [] (jj-cmd (fn [c] ((. c :describe))))) {:exit true :desc "Describe"}]

                     [" " (fn [] (jj-cmd (fn [c] ((. c :commit))))) {:exit true :desc "Commit"}]

                     ["n" (fn [] (jj-cmd (fn [c] ((. c :new))))) {:desc "New"}]

                     ["e" (fn [] (jj-cmd (fn [c] ((. c :edit))))) {:desc "Edit"}]

                     ["S" (fn [] (jj-cmd (fn [c] ((. c :squash))))) {:desc "Squash"}]

                     ["r" (fn [] (jj-cmd (fn [c] ((. c :rebase))))) {:desc "Rebase"}]

                     ["a" (fn [] (jj-cmd (fn [c] ((. c :abandon))))) {:desc "Abandon"}]

                     ["u" (fn [] (jj-cmd (fn [c] ((. c :undo))))) {:desc "Undo"}]

                     ["U" (fn [] (jj-cmd (fn [c] ((. c :redo))))) {:desc "Redo"}]

                     ["f" (fn [] (jj-cmd (fn [c] ((. c :fetch))))) {:desc "Fetch"}]

                     ["p" (fn [] (jj-cmd (fn [c] ((. c :push))))) {:desc "Push"}]

                     ["P" (fn [] (jj-cmd (fn [c] ((. c :open_pr))))) {:exit true :desc "Open PR"}]

                     ["b" (fn [] (jj-cmd (fn [c] ((. c :bookmark_create))))) {:desc "Bookmark create"}]

                     ["t" (fn [] (jj-cmd (fn [c] ((. c :tag_set))))) {:desc "Tag set"}]

                     ["v" (fn [] (jj-diff (fn [d] (d.open_vdiff)))) {:exit true :desc "VDiff"}]

                     ["V" (fn [] (jj-diff (fn [d] (d.open_hdiff)))) {:exit true :desc "HDiff"}]

                     ["o" (fn [] (jj-annotate (fn [a] (a.file)))) {:exit true :desc "Annotate file"}]

                     ["O" (fn [] (jj-annotate (fn [a] (a.line)))) {:exit true :desc "Annotate line"}]

                     ["ps" (fn [] (jj-picker (fn [p] (p.status)))) {:exit true :desc "Picker status"}]

                     ["ph" (fn [] (jj-picker (fn [p] (p.file_history)))) {:exit true :desc "Picker history"}]

                     ["q" nil {:exit true :nowait true :desc "Quit"}]]}))))))
    _jj_hydra)

(fn M.activate_jj_hydra []
  (let [h (ensure-jj-hydra)]
    (when h
      (: h :activate))))

(fn M.activate_git_hydra []
  (let [h (ensure-git-hydra)]
    (when h
      (: h :activate))))

(fn M.toggle_debug_hydra []
  (let [packed [(pcall require :debugmaster)]
        ok (. packed 1)
        dm (. packed 2)]
    (if (not ok)
        (notify-missing "MironPascalCaseFan/debugmaster.nvim")
        (do
          (pcall (fn [] ((. dm.mode :toggle))))
          ;; headless 不弹出 hint（避免浮窗/按键相关报错）
          (when (> (# (vim.api.nvim_list_uis)) 0)
            (let [h (ensure-debug-hydra)]
              (when h
                (pcall (fn [] (: h :activate))))))))))

(fn M.activate_hurl_hydra []
  (let [h (ensure-hurl-hydra)]
    (when h
      (: h :activate))))

(fn M.activate_kulala_hydra []
  (let [h (ensure-kulala-hydra)]
    (when h
      (: h :activate))))

(fn M.activate_neotest_hydra []
  (let [h (ensure-neotest-hydra)]
    (when h
      ;; headless 不弹出 Hydra
      (when (> (# (vim.api.nvim_list_uis)) 0)
        (: h :activate)))))

;; 同一入口键位：根据当前 filetype 自动选择 Hurl / Kulala
(fn M.activate_http_hydra []
  (let [ft vim.bo.filetype]
    (if (= ft "hurl")
        (M.activate_hurl_hydra)
        (M.activate_kulala_hydra))))

(fn M.kulala_open_history []
  (kulala-open-history))

(fn M.activate_conflict_hydra []
  (let [h (ensure-conflict-hydra)]
    (when h
      (: h :activate))))

(fn M.toggle_conflict_view []
  (if (= (get-conflict-view) "conflux")
      (do
        (set-conflict-view "diffview")
        (diffview-open)
        (diffview-focus-files)
        (vim.notify "Conflict 视图：diffview"))
      (do
        (set-conflict-view "conflux")
        (diffview-close)
        (vim.notify "Conflict 视图：conflux"))))

(fn M.conflict_quickfix [] (conflict-list))
(fn M.conflict_next [] (conflict-next))
(fn M.conflict_prev [] (conflict-prev))

(fn M.activate_agentic_hydra []
  (let [h (ensure-agentic-hydra)]
    (when h
      ;; headless 不弹出 Hydra（避免浮窗/按键相关报错）
      (when (> (# (vim.api.nvim_list_uis)) 0)
        (: h :activate)))))

;; 开发工具插件配置
(fn M.setup []
  ;; tmux.nvim - tmux集成
  (gentlewind.use_package
    {:repo "aserowy/tmux.nvim"
     :event "VeryLazy"
     :config (fn []
               ((. (require :tmux) :setup)
                 {:copy_sync {:enable true
                              :sync_clipboard false
                              :sync_registers true}
                  :resize {:enable_default_keybindings false}}))})

  ;; refactoring.nvim - 代码重构工具
  (gentlewind.use_package
    {:repo "ThePrimeagen/refactoring.nvim"
     :dependencies ["lewis6991/async.nvim" "nvim-lua/plenary.nvim" "nvim-treesitter/nvim-treesitter"]
     :cmd ["Refactor"]
     :config (fn []
               ((. (require :refactoring) :setup)
                 {:prompt_func_return_type {:go true :python true :lua true}
                  :prompt_func_param_type {:go true :python true :lua true}
                  :printf_statements {:go true :python true :lua true}
                  :print_var_statements {:go true :python true :lua true}}))})

  ;; nvim-tree-remote.nvim - 远程文件管理
  (gentlewind.use_package {:repo "kiyoon/nvim-tree-remote.nvim" :event "VeryLazy"})

  ;; urlview.nvim - URL查看器
  (gentlewind.use_package {:repo "axieax/urlview.nvim" :cmd ["UrlView"]})

  ;; godbolt.nvim - 在线编译器
  (gentlewind.use_package
    {:repo "p00f/godbolt.nvim"
     :cmd ["Godbolt" "GodboltCompiler"]
     :config (fn []
               ((. (require :godbolt) :setup)
                 {:languages {:cpp {:compiler "g122" :options {}}
                              :c {:compiler "cg122" :options {}}
                              :rust {:compiler "r1650" :options {}}}
                  :quickfix {:enable false
                             :auto_open false}
                  :url "https://godbolt.org"}))})

  ;; messages.nvim - 消息管理
  (gentlewind.use_package
    {:repo "AckslD/messages.nvim"
     :cmd ["Messages"]
     :config (fn [] ((. (require :messages) :setup)))})

  ;; nvim-projector - 项目管理
  (gentlewind.use_package
    {:repo "kndndrj/nvim-projector"
     :dependencies ["MunifTanjim/nui.nvim"
                    "kndndrj/projector-neotest"
                    "nvim-neotest/neotest"
                    "kndndrj/projector-dbee"]
     :cmd ["Projector"]
     :config (fn []
               (local projector_dbee (require :projector_dbee))
               ((. (require :projector) :setup)
                {:outputs [(:new projector_dbee.OutputBuilder)]}))})

  ;; neotest - 测试框架（Go/Python）
  (gentlewind.use_package
    {:repo "nvim-neotest/neotest"
     :cmd ["Neotest"]
     :ft ["go" "python"]
     :dependencies ["nvim-neotest/nvim-nio"
                    "nvim-lua/plenary.nvim"
                    "nvim-treesitter/nvim-treesitter"
                    "nvim-neotest/neotest-go"
                    "nvim-neotest/neotest-python"]
     :config (fn []
               ((. (require :neotest) :setup)
                {:adapters [((require :neotest-go)
                             {:experimental {:test_table true}
                              :args ["-count=1" "-timeout=60s"]
                              :recursive_run true})
                           ((require :neotest-python)
                             {:runner "pytest"
                              :dap {:justMyCode false}})]}))})

  ;; Go: ray-x/go.nvim
  ;; NOTE: 本配置已在 features/lsp 内独立管理 gopls，因此这里关闭 go.nvim 的内置 lsp_cfg，避免重复配置。
  (gentlewind.use_package
    {:repo "ray-x/go.nvim"
     :ft ["go"]
     :dependencies ["ray-x/guihua.lua" "neovim/nvim-lspconfig" "nvim-treesitter/nvim-treesitter"]
     :build ":lua require('go.install').update_all_sync()"
     :config (fn []
               (pcall (fn []
                        ((. (require :go) :setup)
                         {:lsp_cfg false}))))})

  ;; nvim-dap-virtual-text - DAP虚拟文本
  (gentlewind.use_package
    {:repo "theHamsta/nvim-dap-virtual-text"
     :dependencies ["mfussenegger/nvim-dap" "nvim-treesitter/nvim-treesitter"]
     :event "VeryLazy"
     :config (fn []
               ((. (require :nvim-dap-virtual-text) :setup)
                 {:enabled true
                  :enabled_commands true
                  :highlight_changed_variables true
                  :highlight_new_as_changed false
                  :show_stop_reason true
                  :commented false
                  :only_first_definition true
                  :all_references false
                  :clear_on_continue false
                  :display_callback (fn [variable buf stackframe node options]
                                      (if (= "inline" (. options :virt_text_pos))
                                        (.. " = " (string.gsub variable.value "%s+" " "))
                                        (.. variable.name " = " (string.gsub variable.value "%s+" " "))))
                  :virt_text_pos (if (= 1 (vim.fn.has "nvim-0.10")) "inline" "eol")
                  :all_frames false
                  :virt_lines false
                  :virt_text_win_col nil}))})

  ;; hydra.nvim - 子模态/Transient
  (gentlewind.use_package {:repo "anuvyklack/hydra.nvim" :event "VeryLazy"})

  ;; conflux.nvim - 合并冲突解决（VSCode 风格）
  (gentlewind.use_package
    {:repo "muleyuck/conflux.nvim"
     :event ["BufReadPost" "BufWritePost"]
     :config (fn []
               (pcall (fn []
                        ((. (require :conflux) :setup)
                         {:default_mappings false
                          :show_keymap_hints false
                          ;; 禁用全局 cq，避免污染全局键位；统一用 <leader>g c q
                          :quickfix_keymaps {:open false}
                          ;; 走 Diff* link，主题一致（gruvbox 也更协调）
                          :highlights {:ours {:link "DiffAdd"}
                                       :theirs {:link "DiffDelete"}
                                       :base {:link "DiffText"}
                                       :cursor {:link "CursorLine"}}}))))})

  ;; diffview.nvim - Git diff 视图（支持 merge/rebase 的 3-way diff）
  (gentlewind.use_package
    {:repo "sindrets/diffview.nvim"
     :event "VeryLazy"
     :dependencies ["nvim-lua/plenary.nvim" "nvim-tree/nvim-web-devicons"]
     :config (fn []
               (pcall (fn []
                        (local diffview (require :diffview))
                        ((. diffview :setup)
                         {:view {:merge_tool {:layout "diff3_horizontal"}}}))))})

  ;; trouble.nvim - 统一列表面板（diagnostics/quickfix/loclist 等）
  (gentlewind.use_package
    {:repo "folke/trouble.nvim"
     :cmd ["Trouble"]
     :dependencies ["nvim-tree/nvim-web-devicons"]
     :config (fn []
               (pcall (fn []
                        (local trouble (require :trouble))
                        ((. trouble :setup) {}))))})

  ;; nvim-bqf - Quickfix 增强（仅在 qf 窗口生效）
  (gentlewind.use_package
    {:repo "kevinhwang91/nvim-bqf"
     :ft ["qf"]
     :config (fn []
               (pcall (fn []
                        (local bqf (require :bqf))
                        ((. bqf :setup) {}))))})

  ;; persistence.nvim - Session 恢复（手动 restore；不强制自动恢复）
  (gentlewind.use_package
    {:repo "folke/persistence.nvim"
     :event "VimEnter"
     :config (fn []
               (pcall (fn []
                        (local persistence (require :persistence))
                        ((. persistence :setup) {}))))})

  ;; 自动弹出冲突 Hydra：只在当前 buffer 有冲突时触发一次，且不打断 Insert/命令行模式
  (vim.api.nvim_create_autocmd
    ["BufEnter" "BufWinEnter"]
    {:callback (fn []
                 (let [mode (. (vim.api.nvim_get_mode) :mode)]
                   ;; conflux.nvim 目前没有公开的 has_conflicts API，直接用 marker 快速检测。
                   ;; 只要命中任意一个 marker，就弹一次冲突 Hydra。
                  (when (and (not vim.b._conflict_hydra_shown)
                              ;; headless 场景不弹出 Hydra（避免 schedule/浮窗相关报错）
                              (> (# (vim.api.nvim_list_uis)) 0)
                              ;; diffview 面板/视图 buffer 不触发自动弹出（避免循环打断）
                              (or (not vim.bo.filetype)
                                  (not (vim.startswith vim.bo.filetype "Diffview")))
                              (not (or (= mode "c")
                                       (= mode "R")
                                       (vim.startswith mode "i")))
                              (or (> (vim.fn.search "^<<<<<<<" "nw") 0)
                                  (> (vim.fn.search "^=======" "nw") 0)
                                  (> (vim.fn.search "^>>>>>>>" "nw") 0)))
                    (set vim.b._conflict_hydra_shown true)
                    (vim.schedule
                      (fn []
                        (when (= (get-conflict-view) "diffview")
                          (diffview-open)
                          (diffview-focus-files))
                        (M.activate_conflict_hydra))))))})

  ;; Git - gitsigns + neogit（供 Git Hydra 使用）
  (gentlewind.use_package
    {:repo "lewis6991/gitsigns.nvim"
     :event "VeryLazy"
     :opts {}
     :config (fn [] (pcall (fn [] ((. (require :gitsigns) :setup) {}))))})

  (gentlewind.use_package
    {:repo "NeogitOrg/neogit"
     :cmd ["Neogit"]
     :dependencies ["nvim-lua/plenary.nvim"]
     :config (fn [] (pcall (fn [] ((. (require :neogit) :setup) {}))))})

  ;; Debug - nvim-dap + debugmaster.nvim（不要与 dap-ui 混用）
  (gentlewind.use_package
    {:repo "mfussenegger/nvim-dap"
     ;; 通过 cmd 触发 lazy 加载，配合 localleader debug minor-mode
     :cmd ["DapContinue"
           "DapToggleBreakpoint"
           "DapStepOver"
           "DapStepInto"
           "DapStepOut"
           "DapTerminate"
           "DapToggleRepl"
           "DapEval"
           "DapRestartFrame"]
     :event "VeryLazy"})
  (gentlewind.use_package {:repo "jbyuki/one-small-step-for-vimkind" :event "VeryLazy"})
  (gentlewind.use_package
    {:repo "MironPascalCaseFan/debugmaster.nvim"
     :event "VeryLazy"
     :dependencies ["mfussenegger/nvim-dap" "jbyuki/one-small-step-for-vimkind"]
     :config (fn []
               (pcall (fn []
                        (local dm (require :debugmaster))
                        ;; 可按需调整：OSV（调试 Neovim Lua）默认开启
                        (set dm.plugins.osv_integration.enabled true))))})

  ;; zellij-nav.nvim - 统一 Neovim & Zellij pane/tab 导航
  ;; 通过全局开关 vim.g.gentlewind_zellij_nav_enabled 控制是否启用键位（默认 true）
  (gentlewind.use_package
    {:repo "swaits/zellij-nav.nvim"
     :event "VeryLazy"
     :opts {}
     :config (fn []
               (when (or (not vim.g.gentlewind_zellij_nav_enabled)
                         (= vim.g.gentlewind_zellij_nav_enabled true))
                 ;; 保持零配置，键位由 user/config.fnl 统一管理
                 nil))})

  ;; spectre.nvim - 搜索替换工具
  (gentlewind.use_package
    {:repo "nvim-pack/nvim-spectre"
     :cmd ["Spectre"]
     :config (fn [] ((. (require :spectre) :setup)))})

  ;; DB: vim-dadbod + UI + completion
  (gentlewind.use_package
    {:repo "tpope/vim-dadbod"
     :cmd ["DB"]})

  (gentlewind.use_package
    {:repo "kristijanhusak/vim-dadbod-ui"
     :cmd ["DBUI" "DBUIToggle" "DBUIAddConnection" "DBUIFindBuffer"]
     :dependencies ["tpope/vim-dadbod"]
     ;; minimal defaults; further behavior configured via keymaps / env / g:dbs
     :init (fn []
             ;; use nerd font icons only if user already enabled them globally
             (when vim.g.gentlewind_use_nerd_font
               (set vim.g.db_ui_use_nerd_fonts 1)))})

  (gentlewind.use_package
    {:repo "kristijanhusak/vim-dadbod-completion"
     :ft ["sql" "mysql" "plsql"]
     :dependencies ["tpope/vim-dadbod"]})

  ;; CSV/TSV: buffer 内表格化查看（无外部 TUI）
  (gentlewind.use_package
    {:repo "hat0uma/csvview.nvim"
     :cmd ["CsvViewEnable" "CsvViewDisable" "CsvViewToggle" "CsvViewInfo"]
     :ft ["csv" "tsv"]
     :opts {:view {:display_mode "border"
                   :header_lnum 1
                   :sticky_header {:enabled true}}}})

  ;; jq-playground.nvim - 在 Neovim 内交互式跑 jq
  ;; NOTE: 依赖系统 jq；YAML 输入会用 yq。
  (gentlewind.use_package
    {:repo "yochem/jq-playground.nvim"
     :cmd ["JqPlayground"]})

  ;; Python: venv selector（支持 Poetry / uv(PEP-723) 等）
  (gentlewind.use_package
    {:repo "linux-cultist/venv-selector.nvim"
     :cmd ["VenvSelect" "VenvSelectLog" "VenvSelectCache"]
     :ft ["python"]
     :dependencies ["nvim-lua/plenary.nvim"]
     :config (fn []
               ;; 显式 setup，确保 Poetry/uv/PEP-723 能力可用。
               ;; 后续如需指定 picker/backend/search 规则，再在这里补 opts。
               (pcall (fn [] ((. (require :venv-selector) :setup) {}))))})

  ;; hurl.nvim - HTTP客户端
  (gentlewind.use_package
    {:repo "jellydn/hurl.nvim"
     :dependencies ["MunifTanjim/nui.nvim" "nvim-lua/plenary.nvim" "nvim-treesitter/nvim-treesitter"]
     :ft ["hurl"]
     :opts {:debug false
            :show_notification true
            :mode "split"
            :formatters {:json ["jq"]
                         :html ["prettier" "--parser" "html"]
                         :xml ["tidy" "-xml" "-i" "-q"]}
            :mappings {:close "q"
                       :next_panel "<C-n>"
                       :prev_panel "<C-p>"}}
     })

  ;; kulala.nvim - IntelliJ HTTP Client 兼容（.http）
  ;; NOTE: 关闭插件自带全局 keymaps，由我们统一维护入口键位与 minor-mode。
  (gentlewind.use_package
    {:repo "mistweaverco/kulala.nvim"
     :ft ["http" "rest"]
     :opts {:global_keymaps false
            :kulala_keymaps_prefix ""}})

  ;; guihua.lua - UI library (required by multiple plugins)
  (gentlewind.use_package
    {:repo "ray-x/guihua.lua"
     :build "cd lua/fzy && make"})

  ;; web-tools.nvim - Web开发工具
  (gentlewind.use_package
    {:repo "ray-x/web-tools.nvim"
     :dependencies ["ray-x/guihua.lua"]
     :cmd ["Npm" "Yarn" "Npx" "Node" "Pnpm" "StopJob"]
     :config (fn []
               ((. (require :web-tools) :setup)
                 {:keymaps {:rename nil
                            :repeat_rename "."}}))})

  ;; navigator.lua - LSP导航
  (gentlewind.use_package
    {:repo "ray-x/navigator.lua"
     :dependencies ["ray-x/guihua.lua" "neovim/nvim-lspconfig"]
     :event "VeryLazy"})

  ;; sad.nvim - 搜索替换
  ;; （已保留 spectre.nvim，此处移除 sad.nvim 以避免搜索替换工具重复）

  )

M

;; user.modules.config.dev_tools
(local M {})

;; =============================
;; Hydra 子模态（Git / Debug / Hurl）
;; =============================

(var _git_hydra nil)
(var _debug_hydra nil)
(var _hurl_hydra nil)
(var _conflict_hydra nil)
(var _agentic_hydra nil)
(fn notify-missing [what]
  (vim.notify (.. "未启用/未安装：" what) vim.log.levels.WARN))

(fn safe-require [mod]
  (let [packed [(pcall require mod)]
        ok (. packed 1)
        res (. packed 2)]
    (if ok res nil)))

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
        (let [hint (table.concat
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
                  [["e" (fn [] (pcall vim.cmd "HurlRunnerToEntry")) {:desc "Run entry"}]
                   ["r" (fn []
                          ;; 先尝试用最近一次 visual 选区（'<,'>），失败再 fallback 到普通 HurlRunner。
                          (if (not (pcall vim.cmd "'<,'>HurlRunner"))
                              (pcall vim.cmd "HurlRunner")))
                    {:desc "Run"}]
                   ["m" (fn [] (pcall vim.cmd "HurlToggleMode")) {:desc "Toggle mode"}]
                   ["v" (fn [] (pcall vim.cmd "HurlVerbose")) {:desc "Verbose"}]
                   ["q" nil {:exit true :nowait true :desc "Quit"}]]})))))
  _hurl_hydra)

;; Agentic.nvim（ACP / coco）
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
                           [" Agentic (coco)"
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
                            "（提示：provider 已固定为 coco；如需切换 provider 请先在配置里放开 switch_provider）"]
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
     :dependencies ["nvim-lua/plenary.nvim" "nvim-treesitter/nvim-treesitter"]
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
  (gentlewind.use_package {:repo "mfussenegger/nvim-dap" :event "VeryLazy"})
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

  ;; spectre.nvim - 搜索替换工具
  (gentlewind.use_package
    {:repo "nvim-pack/nvim-spectre"
     :cmd ["Spectre"]
     :config (fn [] ((. (require :spectre) :setup)))})

  ;; hurl.nvim - HTTP客户端
  (gentlewind.use_package
    {:repo "jellydn/hurl.nvim"
     :dependencies ["MunifTanjim/nui.nvim" "nvim-lua/plenary.nvim" "nvim-treesitter/nvim-treesitter"]
     :ft ["hurl" "http"]
     :opts {:debug false
            :show_notification true
            :mode "split"
            :formatters {:json ["jq"]
                         :html ["prettier" "--parser" "html"]
                         :xml ["tidy" "-xml" "-i" "-q"]}
            :mappings {:close "q"
                       :next_panel "<C-n>"
                       :prev_panel "<C-p>"}}
     ;; 只保留入口键：<leader>t h（normal/visual 统一进入 Hurl 子模态）
     :keys [["<leader>th" (fn [] (M.activate_hurl_hydra)) :desc "Hurl 菜单"]
            ["<leader>th" (fn [] (M.activate_hurl_hydra)) :desc "Hurl 菜单" :mode "v"]]})

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

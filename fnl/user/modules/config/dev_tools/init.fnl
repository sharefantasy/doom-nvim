;; user.modules.config.dev_tools
(local M {})

;; =============================
;; Hydra 子模态（Git / Debug / Hurl）
;; =============================

(var _git_hydra nil)
(var _debug_hydra nil)
(var _hurl_hydra nil)

(fn notify-missing [what]
  (vim.notify (.. "未启用/未安装：" what) vim.log.levels.WARN))

(fn safe-require [mod]
  (let [packed [(pcall require mod)]
        ok (. packed 1)
        res (. packed 2)]
    (if ok res nil)))

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
                  :config {:color "pink"
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

(fn ensure-debug-hydra []
  (when (not _debug_hydra)
    (local Hydra (safe-require :hydra))
    (if (not Hydra)
        (notify-missing "anuvyklack/hydra.nvim")
        (let [hint (table.concat
                     [" Debug"
                      ""
                      " _c_: continue    _n_: next    _i_: into    _o_: out"
                      " _b_: breakpoint  _B_: cond bp"
                      " _u_: dap-ui      _r_: repl    _t_: terminate"
                      ""
                      " _q_: quit"]
                     "\n")]
          (set _debug_hydra
               (Hydra
                 {:name "Debug"
                  :mode "n"
                  :hint hint
                  :config {:color "amaranth"
                           :invoke_on_body true
                           :hint {:border "rounded" :position "middle"}}
                  :heads
                  [["c" (fn []
                          (local dap (safe-require :dap))
                          (if dap (dap.continue) (notify-missing "mfussenegger/nvim-dap")))
                    {:desc "Continue"}]
                   ["n" (fn []
                          (local dap (safe-require :dap))
                          (if dap (dap.step_over) (notify-missing "mfussenegger/nvim-dap")))
                    {:desc "Step over"}]
                   ["i" (fn []
                          (local dap (safe-require :dap))
                          (if dap (dap.step_into) (notify-missing "mfussenegger/nvim-dap")))
                    {:desc "Step into"}]
                   ["o" (fn []
                          (local dap (safe-require :dap))
                          (if dap (dap.step_out) (notify-missing "mfussenegger/nvim-dap")))
                    {:desc "Step out"}]
                   ["b" (fn []
                          (local dap (safe-require :dap))
                          (if dap (dap.toggle_breakpoint) (notify-missing "mfussenegger/nvim-dap")))
                    {:desc "Toggle BP"}]
                   ["B" (fn []
                          (local dap (safe-require :dap))
                          (if dap
                              (dap.set_breakpoint (vim.fn.input "Breakpoint condition: "))
                              (notify-missing "mfussenegger/nvim-dap")))
                    {:desc "Conditional BP"}]
                   ["u" (fn []
                          (local dapui (safe-require :dapui))
                          (if dapui (dapui.toggle) (notify-missing "rcarriga/nvim-dap-ui")))
                    {:desc "Toggle UI"}]
                   ["r" (fn []
                          (local dap (safe-require :dap))
                          (if dap (dap.repl.toggle) (notify-missing "mfussenegger/nvim-dap")))
                    {:desc "REPL"}]
                   ["t" (fn []
                          (local dap (safe-require :dap))
                          (if dap (dap.terminate) (notify-missing "mfussenegger/nvim-dap")))
                    {:desc "Terminate"}]
                   ["q" nil {:exit true :nowait true :desc "Quit"}]]})))))
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

(fn M.activate_git_hydra []
  (let [h (ensure-git-hydra)]
    (when h
      ((. h :activate)))))

(fn M.activate_debug_hydra []
  (let [h (ensure-debug-hydra)]
    (when h
      ((. h :activate)))))

(fn M.activate_hurl_hydra []
  (let [h (ensure-hurl-hydra)]
    (when h
      ((. h :activate)))))

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

  ;; Debug - nvim-dap + dap-ui（供 Debug Hydra 使用）
  (gentlewind.use_package {:repo "mfussenegger/nvim-dap" :event "VeryLazy"})
  (gentlewind.use_package {:repo "nvim-neotest/nvim-nio" :event "VeryLazy"})
  (gentlewind.use_package
    {:repo "rcarriga/nvim-dap-ui"
     :event "VeryLazy"
     :dependencies ["mfussenegger/nvim-dap" "nvim-neotest/nvim-nio"]
     :config (fn [] (pcall (fn [] ((. (require :dapui) :setup) {}))))})

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

;; gentlewind.modules.features.notes
;; Notes / knowledge-base integrations (Obsidian)

(local M {})

(var _obsidian_warned false)

(fn obsidian-workspaces []
  ;; 允许用户在 `fnl/user/config.fnl` 里配置：
  ;;   (set vim.g.obsidian_workspaces [{:name "notes" :path "~/vault"} ...])
  ;; 或通过环境变量：OBSIDIAN_VAULT=/path/to/vault
  (let [ws (or vim.g.obsidian_workspaces vim.g.gentlewind_obsidian_workspaces)
        env (or vim.env.OBSIDIAN_VAULT vim.env.OBSIDIAN_DIR)]
    (if (and ws (= (type ws) :table) (> (# ws) 0))
        ws
        (if (and env (= (type env) :string) (not= env ""))
            [{:name "obsidian" :path env}]
            []))))

(fn obsidian-setup! []
  (let [ws (obsidian-workspaces)]
    (if (= (# ws) 0)
        (do
          (when (not _obsidian_warned)
            (set _obsidian_warned true)
            (vim.notify
              "obsidian.nvim 未配置 workspace，已跳过 setup（不会影响普通 markdown）。\n可设置 vim.g.obsidian_workspaces 或环境变量 OBSIDIAN_VAULT。"
              vim.log.levels.WARN)))
        (pcall
          (fn []
            ((. (require :obsidian) :setup)
             {:workspaces ws
              ;; 避免把所有 markdown 当成 obsidian buffer
              :detect_cwd false}))))))

(fn obsidian-auto-load! []
  ;; 仅当打开的文件路径位于 workspace 下时，才自动加载 obsidian.nvim
  (let [ws (obsidian-workspaces)]
    (when (> (# ws) 0)
      (vim.api.nvim_create_autocmd
        ["BufReadPre" "BufNewFile"]
        {:pattern "*.md"
         :callback
         (fn [ev]
           (let [path (vim.api.nvim_buf_get_name ev.buf)]
             (when (and path (not= path ""))
               (each [_ w (ipairs ws)]
                 (let [p (. w :path)]
                   (when (and p (not= p "") (vim.startswith path (vim.fn.expand p)))
                     ;; lazy-load once; config 会调用 obsidian-setup!
                     (pcall (fn [] ((. (require :lazy) :load) {:plugins ["obsidian.nvim"]})))))))))}))))

(set M.packages
  {:obsidian {:repo "obsidian-nvim/obsidian.nvim"
              :version "*"
              ;; 不要对所有 markdown 自动 setup；仅通过命令或 vault 内文件自动 load
              :cmd ["Obsidian" "ObsidianQuickSwitch" "ObsidianSearch" "ObsidianToday" "ObsidianNew"]
              :init (fn [] (obsidian-auto-load!))
              :dependencies ["nvim-lua/plenary.nvim"]
              :config (fn [] (obsidian-setup!))}})

(set M.binds {})
(set M.cmds [])
(set M.autocmds [])
(set M.configs {})
(set M.settings {})

{:packages M.packages
 :configs M.configs
 :settings M.settings
 :autocmds M.autocmds
 :cmds M.cmds
 :binds M.binds}

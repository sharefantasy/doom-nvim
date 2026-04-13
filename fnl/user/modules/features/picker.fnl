;; user.modules.features.picker
;; Snacks picker 统一入口（telescope 保留但不启用）

(local M {})

(fn snacks? []
  (let [packed [(pcall require :snacks)]
        ok (. packed 1)]
    ok))

(fn Snacks []
  (require :snacks))

(set M.packages
  {:snacks
   {:repo "folke/snacks.nvim"
    ;; 由于本框架会在启动期直接创建 keymap，Snacks 必须提前可用。
    :lazy false
    :priority 1000
    :config (fn []
              (pcall (fn []
                       ((. (Snacks) :setup)
                        {:picker {:enabled true}
                         ;; 体验增强组件（整体替换 telescope 并加强 UI）
                         :notifier {:enabled true}
                         :input {:enabled true}
                         :indent {:enabled true}
                         :statuscolumn {:enabled true}
                         :dashboard {:enabled true}
                         :explorer {:enabled true}
                         :terminal {:enabled true}
                         :lazygit {:enabled true}

                         ;; 其他常用增强（默认也打开，基本低侵入）
                         :bufdelete {:enabled true}
                         :toggle {:enabled true}
                         :scroll {:enabled true}
                         :scope {:enabled true}
                         :words {:enabled true}
                         :gitbrowse {:enabled true}
                         :zen {:enabled true}

                         ;; 避免引入额外依赖/平台限制：先不启用 image/gh
                         :image {:enabled false}
                         :gh {:enabled false}}))))}})

(fn call [f]
  (if (snacks?)
      (pcall f)
      (vim.notify "snacks.nvim 未加载（请确认已启用 features: picker）" vim.log.levels.WARN)))

(set M.binds
  {:<leader>p {:name "+picker"
               :p {:desc "项目" :cmd (fn [] (call (fn [] ((. (. (Snacks) :picker) :projects)))))}
               :f {:desc "找文件" :cmd (fn [] (call (fn [] ((. (. (Snacks) :picker) :files)))))}
               :g {:desc "全文搜" :cmd (fn [] (call (fn [] ((. (. (Snacks) :picker) :grep)))))}
               :b {:desc "缓冲" :cmd (fn [] (call (fn [] ((. (. (Snacks) :picker) :buffers)))))}
               :h {:desc "帮助" :cmd (fn [] (call (fn [] ((. (. (Snacks) :picker) :help)))))}
               :k {:desc "键位" :cmd (fn [] (call (fn [] ((. (. (Snacks) :picker) :keymaps)))))}
               :c {:desc "命令" :cmd (fn [] (call (fn [] ((. (. (Snacks) :picker) :commands)))))}
               :s {:desc "Git 状态" :cmd (fn [] (call (fn [] ((. (. (Snacks) :picker) :git_status)))))}
               :B {:desc "Git 分支" :cmd (fn [] (call (fn [] ((. (. (Snacks) :picker) :git_branches)))))}
               :l {:desc "Git 日志" :cmd (fn [] (call (fn [] ((. (. (Snacks) :picker) :git_log)))))}
               :t {:desc "Picker 列表" :cmd (fn [] (call (fn [] ((. (. (Snacks) :picker) :pickers)))))}
               }
   :<leader>/ {:desc "全局搜索" :cmd (fn [] (call (fn [] ((. (. (Snacks) :picker) :grep)))))} })

;; 常用工具入口（snacks 组件）
(tset M.binds :<leader>t
      {:name "+tools"
       :t {:desc "终端" :cmd (fn [] (call (fn [] ((. (Snacks) :terminal))))) }
       :g {:desc "LazyGit" :cmd (fn [] (call (fn [] ((. (Snacks) :lazygit))))) }
       :e {:desc "文件浏览" :cmd (fn [] (call (fn [] ((. (Snacks) :explorer))))) }})

(set M.configs {})
(set M.settings {})
(set M.autocmds [])
(set M.cmds [])

{:packages M.packages
 :configs M.configs
 :settings M.settings
 :autocmds M.autocmds
 :cmds M.cmds
 :binds M.binds}

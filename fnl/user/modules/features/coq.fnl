;; user.modules.features.coq
;; COQ.nvim completion (替代 nvim-cmp)

(local M {})

(set M.packages
  {:coq
   {:repo "ms-jpq/coq_nvim"
   :branch "coq"
    ;; COQ 需要尽早可用（本框架会启动期创建 keymap/初始化 LSP）
    :lazy false
    :dependencies [{1 "ms-jpq/coq.artifacts" :branch "artifacts"}
                   {1 "ms-jpq/coq.thirdparty" :branch "3p"}]
    :config (fn []
              ;; 必须在 require('coq') 之前设置
              (set vim.g.coq_settings
                   {:auto_start true
                    :keymap {:recommended true}
                    ;; 常用体验选项（可后续再调）
                    :display {:pum {:fast_close false}}})
              (pcall require :coq))}})

(set M.configs {})
(set M.settings {})
(set M.autocmds [])
(set M.cmds [])
(set M.binds [])

{:packages M.packages
 :configs M.configs
 :settings M.settings
 :autocmds M.autocmds
 :cmds M.cmds
 :binds M.binds}

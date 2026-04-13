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
              (pcall require :coq)

              ;; coq.thirdparty: 根据当前启用语言开启可用的 third party / builtin 源
              ;; 说明：builtin/* 来自 nvim 自带 runtime 的 vimscript omnicomplete（可能会跑较多 vimscript）
              (let [(ok3p coq3p) (pcall require :coq_3p)]
                (when ok3p
                  (coq3p
                    [{:src "nvimlua" :short_name "nLUA"}
                     {:src "builtin/syntax" :short_name "SYN"}

                     ;; Go / Python：coq.thirdparty 没有 builtin/go/python，使用 LSP omnifunc 作为补充来源
                     ;; 注意：这会再次走 LSP 通道，但作为兜底/补充（尤其是 LSP capability 路径异常时）
                     {:src "omnifunc"
                      :short_name "OMNI"
                      :omnifunc "v:lua.vim.lsp.omnifunc"
                      :use_cache true
                      :filetypes ["go" "python"]}

                     ;; 与当前启用语言对齐（见 fnl/user/modules.fnl）
                     {:src "builtin/clojure"}
                     {:src "builtin/haskell"}
                     {:src "builtin/html"}
                     {:src "builtin/css"}
                     {:src "builtin/js"}
                     {:src "builtin/php"}
                     {:src "builtin/c"}
                     {:src "builtin/xml"}

                     ;; 集成：nvim-dap
                     {:src "dap"}]))))}})

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

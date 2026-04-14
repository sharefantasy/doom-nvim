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
                    ;; 注意：<CR> 已用于确认补全（recommended keymap），不建议同时作为 placeholder 跳转键。
                    ;; 这里把 jump_to_mark 设为 <C-l>，避免与确认键语义冲突。
                    :keymap {:recommended true
                             :jump_to_mark "<C-l>"}
                    ;; 更贴近直觉：更积极地用候选替换你已输入的前缀
                    :completion {:replace_prefix_threshold 1
                                 :replace_suffix_threshold 1}
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

                     ;; 集成：nvim-dap（需要 nvim-dap 先加载，否则 coq.thirdparty 会 require('dap.repl') 报错）
                     ;; 如需 dap 补全，可在后续把该源改为在 dap 可用时再注册。
                     ]))))}})

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

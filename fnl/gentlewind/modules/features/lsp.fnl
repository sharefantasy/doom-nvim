;; gentlewind.modules.features.lsp
;; LSP (Language Server Protocol) support for gentlewind-nvim

(local lsp {})

(set lsp.settings
  {:disable_lsp false
   :disable_formatting false
   :disable_diagnostics false
   :lsp_highlight_diagnostics true
   :lsp_sign_priority 10
   :lsp_signs_error "✗"
   :lsp_signs_warning "⚠"
   :lsp_signs_hint "💡"
   :lsp_signs_information "ℹ"})

(set lsp.packages
  {:mason {:repo "williamboman/mason.nvim" :config (fn [] ((. (require :mason) :setup)))}
   :fidget {:repo "j-hui/fidget.nvim"
            :event "LspAttach"
            :config (fn []
                      ((. (require :fidget) :setup)
                        {:progress {:display {:render_limit 8
                                              :done_ttl 3
                                              :progress_ttl 60}}
                         :notification {:window {:winblend 0}}}))}
   :mason-tool-installer {:repo "WhoIsSethDaniel/mason-tool-installer.nvim"
                          :dependencies ["williamboman/mason.nvim"]
                          :config (fn []
                                    ((. (require :mason-tool-installer) :setup)
                                     {:ensure_installed [
                                                         ;; formatters (used by conform.nvim)
                                                         "stylua"
                                                         "goimports"
                                                         "prettierd"
                                                         {1 "ruff" :version "0.15.7"}]
                                      :auto_update false
                                      :run_on_start true}))}
   :mason-lspconfig {:repo "williamboman/mason-lspconfig.nvim"
                     :dependencies ["williamboman/mason.nvim"]
                     :config (fn []
                                ((. (require :mason-lspconfig) :setup) {:automatic_installation true}))}
   :lspconfig {:repo "neovim/nvim-lspconfig"
               :dependencies ["williamboman/mason-lspconfig.nvim"]
               :config (fn []
                         ;; 使用 Neovim 0.11+ 原生 LSP config API，避免 require('lspconfig') 的弃用堆栈。
                         (var capabilities (vim.lsp.protocol.make_client_capabilities))
                         (let [(ok coq) (pcall require :coq)]
                           (when ok
                             (set capabilities ((. coq :lsp_ensure_capabilities) capabilities))))
                         (vim.lsp.config "*" {:capabilities capabilities})

                         (local servers ((. (require :mason-lspconfig) :get_installed_servers)))

                         ;; stylua 不是标准 LSP server（格式化交给 conform.nvim），跳过。
                         (local enabled [])
                         (each [_ server (ipairs servers)]
                           (when (not= server "stylua")
                             (table.insert enabled server)))

                         ;; lua_ls：固定 cache/log 路径 + 收缩 workspace 扫描范围
                         (when (vim.tbl_contains enabled "lua_ls")
                           (local state_dir (vim.fn.stdpath "state"))
                           (local base (vim.fs.joinpath state_dir "lua_ls"))
                           (local logpath (vim.fs.joinpath base "log"))
                           (local metapath (vim.fs.joinpath base "meta"))
                           (local rt (or vim.env.VIMRUNTIME (vim.fn.expand "$VIMRUNTIME")))
                           (local library {})
                           (when (and rt (not= rt ""))
                             (tset library rt true))
                           (vim.fn.mkdir logpath "p")
                           (vim.fn.mkdir metapath "p")
                           (vim.lsp.config "lua_ls"
                             {:cmd ["lua-language-server"
                                    "--logpath" logpath
                                    "--metapath" metapath]
                              :settings {:Lua {:runtime {:version "LuaJIT"}
                                               :diagnostics {:globals ["vim"]}
                                               :workspace {:checkThirdParty false
                                                           :useGitIgnore true
                                                           :ignoreSubmodules true
                                                           :ignoreDir ["lua/gentlewind/**"
                                                                       "lua/user/**"
                                                                       "node_modules/**"
                                                                       ".git/**"
                                                                       ".cache/**"]
                                                           :maxPreload 1000
                                                           :preloadFileSize 200
                                                           :library library}
                                               :telemetry {:enable false}}}}))

                         ;; 启用自动 attach
                         (vim.lsp.enable enabled))}
   })

(set lsp.configs {})
(set lsp.autocmds
  [{:LspAttach "*"
    :desc "Set LSP keymaps on attach"
    :callback (fn [args]
                (local bufnr args.buf)

                (local map (fn [mode lhs rhs desc]
                             (vim.keymap.set mode lhs rhs {:buffer bufnr
                                                           :silent true
                                                           :noremap true
                                                           :desc desc})))

                ;; hover / signature
                (map "n" "K" vim.lsp.buf.hover "Hover 文档")
                (map "n" "gK" vim.lsp.buf.signature_help "Signature")
                (map "i" "<C-k>" vim.lsp.buf.signature_help "Signature")

                ;; go-to
                (map "n" "gd" vim.lsp.buf.definition "跳转定义")
                (map "n" "gD" vim.lsp.buf.declaration "跳转声明")
                (map "n" "gi" vim.lsp.buf.implementation "跳转实现")
                (map "n" "gr" vim.lsp.buf.references "查找引用")
                (map "n" "gy" vim.lsp.buf.type_definition "跳转类型")

                ;; actions
                (map "n" "<leader>rn" vim.lsp.buf.rename "重命名")
                (map "n" "<leader>ca" vim.lsp.buf.code_action "代码操作")
                (map "n" "<leader>f" (fn [] (vim.lsp.buf.format {:async true})) "格式化")

                ;; diagnostics
                (map "n" "[d" vim.diagnostic.goto_prev "上一条诊断")
                (map "n" "]d" vim.diagnostic.goto_next "下一条诊断")
                (map "n" "<leader>e" vim.diagnostic.open_float "浮窗诊断")
                (map "n" "<leader>q" vim.diagnostic.setloclist "诊断列表")

                ;; nice borders for hover/signature
                (tset vim.lsp.handlers
                      "textDocument/hover"
                      (fn [err result ctx config]
                        (local cfg (or config {}))
                        (tset cfg :border "rounded")
                        (vim.lsp.handlers.hover err result ctx cfg)))
                (tset vim.lsp.handlers
                      "textDocument/signatureHelp"
                      (fn [err result ctx config]
                        (local cfg (or config {}))
                        (tset cfg :border "rounded")
                        (vim.lsp.handlers.signature_help err result ctx cfg))))}])
(set lsp.cmds [])
(set lsp.binds [])

{:packages lsp.packages
 :configs lsp.configs
 :settings lsp.settings
 :autocmds lsp.autocmds
 :cmds lsp.cmds
 :binds lsp.binds}

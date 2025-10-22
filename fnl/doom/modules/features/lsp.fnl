;; doom.modules.features.lsp
;; LSP (Language Server Protocol) support for doom-nvim

(local lsp {})

(lsp.settings
  {:disable_lsp false
   :disable_formatting false
   :disable_diagnostics false
   :lsp_highlight_diagnostics true
   :lsp_sign_priority 10
   :lsp_signs_error "✗"
   :lsp_signs_warning "⚠"
   :lsp_signs_hint "💡"
   :lsp_signs_information "ℹ"})

(lsp.packages
  {:mason {:"williamboman/mason.nvim" :config (fn [] (require :mason).setup)}
   :mason-lspconfig {:"williamboman/mason-lspconfig.nvim"
                      :dependencies [:mason]
                      :config (fn []
                                (require :mason-lspconfig).setup
                                  {:automatic_installation true}))}
   :lspconfig {:"neovim/nvim-lspconfig"
                :dependencies [:mason-lspconfig]
                :config (fn []
                          (local lspconfig (require :lspconfig))
                          (local capabilities (require :cmp_nvim_lsp).default_capabilities)
                          
                          ;; Setup default capabilities for all LSP servers
                          (fn setup-server [server-name]
                            (lspconfig[server-name].setup {:capabilities capabilities}))
                          
                          ;; Auto-setup known servers
                          (each [server (require :mason-lspconfig).get_installed_servers]
                            (setup-server server)))}
   :cmp {:"hrsh7th/nvim-cmp"
          :dependencies [:cmp-buffer :cmp-path :cmp-nvim-lua :cmp-nvim-lsp]
          :config (fn []
                    (local cmp (require :cmp))
                    (cmp.setup
                      {:mapping (cmp.mapping.preset.insert
                                   {:["<C-b>"] (cmp.mapping.scroll_docs -4)
                                    :["<C-f>"] (cmp.mapping.scroll_docs 4)
                                    :["<C-Space>"] (cmp.mapping.complete)
                                    :["<C-e>"] (cmp.mapping.abort)
                                    :["<CR>"] (cmp.mapping.confirm {:select true})})
                       :sources cmp.config.sources[{:name :nvim_lsp}
                                                   {:name :buffer}
                                                   {:name :path}]})))}
   :cmp-buffer {:"hrsh7th/cmp-buffer"}
   :cmp-path {:"hrsh7th/cmp-path"}
   :cmp-nvim-lua {:"hrsh7th/cmp-nvim-lua"}
   :cmp-nvim-lsp {:"hrsh7th/cmp-nvim-lsp"}})

(lsp.configs {})
(lsp.autocmds [])
(lsp.cmds [])
(lsp.binds [])

{: packages lsp.packages
 : configs lsp.configs
 : settings lsp.settings
 : autocmds lsp.autocmds
 : cmds lsp.cmds
 : binds lsp.binds}
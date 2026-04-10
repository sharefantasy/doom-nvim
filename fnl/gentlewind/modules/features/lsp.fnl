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
                         (local lspconfig (require :lspconfig))
                         (local capabilities ((. (require :cmp_nvim_lsp) :default_capabilities)))
                         
                         ;; Auto-setup installed LSP servers.
                         ;; Avoid indexing unknown configs (it emits warnings like "config 'stylua' not found").
                         (let [known (require :lspconfig.configs)]
                           (each [_ server (ipairs ((. (require :mason-lspconfig) :get_installed_servers)))]
                             (when (. known server)
                               ((. (. lspconfig server) :setup) {:capabilities capabilities}))))) }
   :cmp {:repo "hrsh7th/nvim-cmp"
         :dependencies ["hrsh7th/cmp-buffer"
                        "hrsh7th/cmp-path"
                        "hrsh7th/cmp-nvim-lua"
                        "hrsh7th/cmp-nvim-lsp"]
         :config (fn []
                   (local cmp (require :cmp))
                   (local sources [{:name :nvim_lsp}
                                   {:name :buffer}
                                   {:name :path}])
                   (cmp.setup
                     {:mapping (cmp.mapping.preset.insert
                                  {"<C-b>" (cmp.mapping.scroll_docs -4)
                                   "<C-f>" (cmp.mapping.scroll_docs 4)
                                   "<C-Space>" (cmp.mapping.complete)
                                   "<C-e>" (cmp.mapping.abort)
                                   "<CR>" (cmp.mapping.confirm {:select true})})
                      :sources (cmp.config.sources sources)}))}
   :cmp-buffer {:repo "hrsh7th/cmp-buffer"}
   :cmp-path {:repo "hrsh7th/cmp-path"}
   :cmp-nvim-lua {:repo "hrsh7th/cmp-nvim-lua"}
   :cmp-nvim-lsp {:repo "hrsh7th/cmp-nvim-lsp"}})

(set lsp.configs {})
(set lsp.autocmds [])
(set lsp.cmds [])
(set lsp.binds [])

{:packages lsp.packages
 :configs lsp.configs
 :settings lsp.settings
 :autocmds lsp.autocmds
 :cmds lsp.cmds
 :binds lsp.binds}

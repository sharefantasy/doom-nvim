;; gentlewind.modules.langs.go
;; Go language support for gentlewind-nvim

(local go {})

(go.settings
  {:disable_treesitter false
   :treesitter_grammars "go"
   :disable_lsp false
   :lsp_name "gopls"
   :disable_formatting false
   :formatting_package "gofumpt"
   :formatting_provider "builtins.formatting.gofumpt"
   :formatting_config nil})

(go.packages
  {:go-nvim {:repo "ray-x/go.nvim"
              :dependencies [:lspconfig]
              :config (fn []
                        (require :go).setup {:lsp_cfg false  ;; Use mason-lspconfig instead
                                             :lsp_gofumpt true
                                             :lsp_on_attach (fn [client bufnr]
                                                               ;; Custom on_attach
                                                               )})}})

(go.configs {})

(local langs_utils (require :gentlewind.modules.langs.utils))

(go.autocmds
  [{:FileType :go
    :callback (langs_utils.wrap_language_setup "go" (fn []
                                            (when (not go.settings.disable_lsp)
                                              (langs_utils.use_lsp_mason go.settings.lsp_name))
                                            
                                            (when (not go.settings.disable_treesitter)
                                              (langs_utils.use_tree_sitter go.settings.treesitter_grammars))
                                            
                                            (when (not go.settings.disable_formatting)
                                              (langs_utils.use_null_ls go.settings.formatting_package
                                                                      go.settings.formatting_provider
                                                                      go.settings.formatting_config))))
    :once true}])

(go.cmds [])
(go.binds [])

{:packages go.packages
 :configs go.configs
 :settings go.settings
 :autocmds go.autocmds
 :cmds go.cmds
 :binds go.binds}
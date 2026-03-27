;; gentlewind.modules.langs.json
;; JSON language support for gentlewind-nvim

(local json {})

(json.settings
  {:disable_treesitter false
   :treesitter_grammars "json"
   :disable_lsp false
   :lsp_name "jsonls"
   :disable_formatting false
   :formatting_package "prettier"
   :formatting_provider "builtins.formatting.prettier"
   :formatting_config nil})

(json.packages {})
(json.configs {})

(local langs_utils (require :gentlewind.modules.langs.utils))

(json.autocmds
  [{:FileType :json
    :callback (langs_utils.wrap_language_setup "json" (fn []
                                            (when (not json.settings.disable_lsp)
                                              (langs_utils.use_lsp_mason json.settings.lsp_name))
                                            
                                            (when (not json.settings.disable_treesitter)
                                              (langs_utils.use_tree_sitter json.settings.treesitter_grammars))
                                            
                                            (when (not json.settings.disable_formatting)
                                              (langs_utils.use_null_ls json.settings.formatting_package
                                                                      json.settings.formatting_provider
                                                                      json.settings.formatting_config))))
    :once true}])

(json.cmds [])
(json.binds [])

{:packages json.packages
 :configs json.configs
 :settings json.settings
 :autocmds json.autocmds
 :cmds json.cmds
 :binds json.binds}
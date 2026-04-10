;; gentlewind.modules.langs.json
;; JSON language support for gentlewind-nvim

(local json {})

(set json.settings
  {:disable_treesitter false
   :treesitter_grammars "json"
   :disable_lsp false
   :lsp_name "jsonls"
   :disable_formatting false
   :formatting_package "prettier"
   :formatting_provider "builtins.formatting.prettier"
   :formatting_config nil})

(set json.packages {})
(set json.configs {})

(local langs_utils (require :gentlewind.modules.langs.utils))

(set json.autocmds
  [{:FileType :json
    :callback (langs_utils.wrap_language_setup "json" (fn []
                                            (when (not json.settings.disable_lsp)
                                              (langs_utils.use_lsp_mason json.settings.lsp_name))
                                            
                                            (when (not json.settings.disable_treesitter)
                                              (langs_utils.use_tree_sitter json.settings.treesitter_grammars))
                                            ))
    :once true}])

(set json.cmds [])
(set json.binds [])

{:packages json.packages
 :configs json.configs
 :settings json.settings
 :autocmds json.autocmds
 :cmds json.cmds
 :binds json.binds}

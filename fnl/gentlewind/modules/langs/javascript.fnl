;; gentlewind.modules.langs.javascript
;; JavaScript/TypeScript language support for gentlewind-nvim

(local javascript {})

(set javascript.settings
  {:disable_treesitter false
   :treesitter_grammars ["javascript" "typescript" "tsx"]
   :disable_lsp false
   :lsp_name "tsserver"
   :disable_formatting false
   :formatting_package "prettier"
   :formatting_provider "builtins.formatting.prettier"
   :formatting_config nil})

(set javascript.packages {})
(set javascript.configs {})

(local langs_utils (require :gentlewind.modules.langs.utils))

(set javascript.autocmds
  [{:FileType [:javascript :typescript :tsx]
    :callback (langs_utils.wrap_language_setup "javascript" (fn []
                                                    (when (not javascript.settings.disable_lsp)
                                                      (langs_utils.use_lsp_mason javascript.settings.lsp_name))
                                                    
                                                    (when (not javascript.settings.disable_treesitter)
                                                      (langs_utils.use_tree_sitter javascript.settings.treesitter_grammars))
                                                    ))
    :once true}])

(set javascript.cmds [])
(set javascript.binds [])

{:packages javascript.packages
 :configs javascript.configs
 :settings javascript.settings
 :autocmds javascript.autocmds
 :cmds javascript.cmds
 :binds javascript.binds}

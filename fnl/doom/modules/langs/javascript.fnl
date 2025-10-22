;; doom.modules.langs.javascript
;; JavaScript/TypeScript language support for doom-nvim

(local javascript {})

(javascript.settings
  {:disable_treesitter false
   :treesitter_grammars ["javascript" "typescript" "tsx"]
   :disable_lsp false
   :lsp_name "tsserver"
   :disable_formatting false
   :formatting_package "prettier"
   :formatting_provider "builtins.formatting.prettier"
   :formatting_config nil})

(javascript.packages {})
(javascript.configs {})

(local langs_utils (require :doom.modules.langs.utils))

(javascript.autocmds
  [{:FileType [:javascript :typescript :tsx]
    (langs_utils.wrap_language_setup "javascript" (fn []
                                                    (when (not javascript.settings.disable_lsp)
                                                      (langs_utils.use_lsp_mason javascript.settings.lsp_name))
                                                    
                                                    (when (not javascript.settings.disable_treesitter)
                                                      (langs_utils.use_tree_sitter javascript.settings.treesitter_grammars))
                                                    
                                                    (when (not javascript.settings.disable_formatting)
                                                      (langs_utils.use_null_ls javascript.settings.formatting_package
                                                                              javascript.settings.formatting_provider
                                                                              javascript.settings.formatting_config))))
    :once true}])

(javascript.cmds [])
(javascript.binds [])

{: packages javascript.packages
 : configs javascript.configs
 : settings javascript.settings
 : autocmds javascript.autocmds
 : cmds javascript.cmds
 : binds javascript.binds}
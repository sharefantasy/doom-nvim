;; doom.modules.langs.typescript
;; TypeScript language support for doom-nvim

(local typescript {})

(typescript.settings
  {:disable_treesitter false
   :treesitter_grammars ["typescript" "tsx"]
   :disable_lsp false
   :lsp_name "tsserver"
   :disable_formatting false
   :formatting_package "prettier"
   :formatting_provider "builtins.formatting.prettier"
   :formatting_config nil})

(typescript.packages {})
(typescript.configs {})

(local langs_utils (require :doom.modules.langs.utils))

(typescript.autocmds
  [{:FileType [:typescript :tsx]
    (langs_utils.wrap_language_setup "typescript" (fn []
                                                    (when (not typescript.settings.disable_lsp)
                                                      (langs_utils.use_lsp_mason typescript.settings.lsp_name))
                                                    
                                                    (when (not typescript.settings.disable_treesitter)
                                                      (langs_utils.use_tree_sitter typescript.settings.treesitter_grammars))
                                                    
                                                    (when (not typescript.settings.disable_formatting)
                                                      (langs_utils.use_null_ls typescript.settings.formatting_package
                                                                              typescript.settings.formatting_provider
                                                                              typescript.settings.formatting_config))))
    :once true}])

(typescript.cmds [])
(typescript.binds [])

{: packages typescript.packages
 : configs typescript.configs
 : settings typescript.settings
 : autocmds typescript.autocmds
 : cmds typescript.cmds
 : binds typescript.binds}
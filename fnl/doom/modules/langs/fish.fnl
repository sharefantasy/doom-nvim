;; doom.modules.langs.fish
;; Fish shell language support for doom-nvim

(local fish {})

(fish.settings
  {:disable_treesitter false
   :treesitter_grammars "fish"
   :disable_lsp false
   :lsp_name "fish_lsp"
   :disable_formatting false
   :formatting_package "fish_indent"
   :formatting_provider "builtins.formatting.fish_indent"
   :formatting_config nil})

(fish.packages {})
(fish.configs {})

(local langs_utils (require :doom.modules.langs.utils))

(fish.autocmds
  [{:FileType :fish
    (langs_utils.wrap_language_setup "fish" (fn []
                                            (when (not fish.settings.disable_lsp)
                                              (langs_utils.use_lsp_mason fish.settings.lsp_name))
                                            
                                            (when (not fish.settings.disable_treesitter)
                                              (langs_utils.use_tree_sitter fish.settings.treesitter_grammars))
                                            
                                            (when (not fish.settings.disable_formatting)
                                              (langs_utils.use_null_ls fish.settings.formatting_package
                                                                      fish.settings.formatting_provider
                                                                      fish.settings.formatting_config))))
    :once true}])

(fish.cmds [])
(fish.binds [])

{: packages fish.packages
 : configs fish.configs
 : settings fish.settings
 : autocmds fish.autocmds
 : cmds fish.cmds
 : binds fish.binds}
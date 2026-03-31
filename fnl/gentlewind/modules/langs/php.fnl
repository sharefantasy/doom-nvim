;; gentlewind.modules.langs.php
;; PHP language support for gentlewind-nvim

(local php {})

(set php.settings
  {:disable_treesitter false
   :treesitter_grammars "php"
   :disable_lsp false
   :lsp_name "intelephense"
   :disable_formatting false
   :formatting_package "php-cs-fixer"
   :formatting_provider "builtins.formatting.phpcsfixer"
   :formatting_config nil})

(set php.packages {})
(set php.configs {})

(local langs_utils (require :gentlewind.modules.langs.utils))

(set php.autocmds
  [{:FileType :php
    :callback (langs_utils.wrap_language_setup "php" (fn []
                                            (when (not php.settings.disable_lsp)
                                              (langs_utils.use_lsp_mason php.settings.lsp_name))
                                            
                                            (when (not php.settings.disable_treesitter)
                                              (langs_utils.use_tree_sitter php.settings.treesitter_grammars))
                                            
                                            (when (not php.settings.disable_formatting)
                                              (langs_utils.use_null_ls php.settings.formatting_package
                                                                      php.settings.formatting_provider
                                                                      php.settings.formatting_config))))
    :once true}])

(set php.cmds [])
(set php.binds [])

{:packages php.packages
 :configs php.configs
 :settings php.settings
 :autocmds php.autocmds
 :cmds php.cmds
 :binds php.binds}
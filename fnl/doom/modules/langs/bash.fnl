;; doom.modules.langs.bash
;; Bash language support for doom-nvim

(local bash {})

(bash.settings
  {:disable_treesitter false
   :treesitter_grammars "bash"
   :disable_lsp false
   :lsp_name "bashls"
   :disable_formatting false
   :formatting_package "shfmt"
   :formatting_provider "builtins.formatting.shfmt"
   :formatting_config nil})

(bash.packages {})
(bash.configs {})

(local langs_utils (require :doom.modules.langs.utils))

(bash.autocmds
  [{:FileType [:bash :sh]
    (langs_utils.wrap_language_setup "bash" (fn []
                                            (when (not bash.settings.disable_lsp)
                                              (langs_utils.use_lsp_mason bash.settings.lsp_name))
                                            
                                            (when (not bash.settings.disable_treesitter)
                                              (langs_utils.use_tree_sitter bash.settings.treesitter_grammars))
                                            
                                            (when (not bash.settings.disable_formatting)
                                              (langs_utils.use_null_ls bash.settings.formatting_package
                                                                      bash.settings.formatting_provider
                                                                      bash.settings.formatting_config))))
    :once true}])

(bash.cmds [])
(bash.binds [])

{: packages bash.packages
 : configs bash.configs
 : settings bash.settings
 : autocmds bash.autocmds
 : cmds bash.cmds
 : binds bash.binds}
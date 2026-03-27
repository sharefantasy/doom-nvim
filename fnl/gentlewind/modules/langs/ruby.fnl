;; gentlewind.modules.langs.ruby
;; Ruby language support for gentlewind-nvim

(local ruby {})

(ruby.settings
  {:disable_treesitter false
   :treesitter_grammars "ruby"
   :disable_lsp false
   :lsp_name "solargraph"
   :disable_formatting false
   :formatting_package "rubocop"
   :formatting_provider "builtins.formatting.rubocop"
   :formatting_config nil})

(ruby.packages {})
(ruby.configs {})

(local langs_utils (require :gentlewind.modules.langs.utils))

(ruby.autocmds
  [{:FileType :ruby
    :callback (langs_utils.wrap_language_setup "ruby" (fn []
                                            (when (not ruby.settings.disable_lsp)
                                              (langs_utils.use_lsp_mason ruby.settings.lsp_name))
                                            
                                            (when (not ruby.settings.disable_treesitter)
                                              (langs_utils.use_tree_sitter ruby.settings.treesitter_grammars))
                                            
                                            (when (not ruby.settings.disable_formatting)
                                              (langs_utils.use_null_ls ruby.settings.formatting_package
                                                                      ruby.settings.formatting_provider
                                                                      ruby.settings.formatting_config))))
    :once true}])

(ruby.cmds [])
(ruby.binds [])

{:packages ruby.packages
 :configs ruby.configs
 :settings ruby.settings
 :autocmds ruby.autocmds
 :cmds ruby.cmds
 :binds ruby.binds}
;; gentlewind.modules.langs.toml
;; TOML language support for gentlewind-nvim

(local toml {})

(toml.settings
  {:disable_treesitter false
   :treesitter_grammars "toml"
   :disable_lsp false
   :lsp_name "taplo"
   :disable_formatting false
   :formatting_package "taplo"
   :formatting_provider "builtins.formatting.taplo"
   :formatting_config nil})

(toml.packages {})
(toml.configs {})

(local langs_utils (require :gentlewind.modules.langs.utils))

(toml.autocmds
  [{:FileType :toml
    :callback (langs_utils.wrap_language_setup "toml" (fn []
                                            (when (not toml.settings.disable_lsp)
                                              (langs_utils.use_lsp_mason toml.settings.lsp_name))
                                            
                                            (when (not toml.settings.disable_treesitter)
                                              (langs_utils.use_tree_sitter toml.settings.treesitter_grammars))
                                            
                                            (when (not toml.settings.disable_formatting)
                                              (langs_utils.use_null_ls toml.settings.formatting_package
                                                                      toml.settings.formatting_provider
                                                                      toml.settings.formatting_config))))
    :once true}])

(toml.cmds [])
(toml.binds [])

{:packages toml.packages
 :configs toml.configs
 :settings toml.settings
 :autocmds toml.autocmds
 :cmds toml.cmds
 :binds toml.binds}
;; gentlewind.modules.langs.toml
;; TOML language support for gentlewind-nvim

(local toml {})

(set toml.settings
  {:disable_treesitter false
   :treesitter_grammars "toml"
   :disable_lsp false
   :lsp_name "taplo"
   :disable_formatting false
   :formatting_package "taplo"
   :formatting_provider "builtins.formatting.taplo"
   :formatting_config nil})

(set toml.packages {})
(set toml.configs {})

(local langs_utils (require :gentlewind.modules.langs.utils))

(set toml.autocmds
  [{:FileType :toml
    :callback (langs_utils.wrap_language_setup "toml" (fn []
                                            (when (not toml.settings.disable_lsp)
                                              (langs_utils.use_lsp_mason toml.settings.lsp_name))
                                            
                                            (when (not toml.settings.disable_treesitter)
                                              (langs_utils.use_tree_sitter toml.settings.treesitter_grammars))
                                            ))
    :once true}])

(set toml.cmds [])
(set toml.binds [])

{:packages toml.packages
 :configs toml.configs
 :settings toml.settings
 :autocmds toml.autocmds
 :cmds toml.cmds
 :binds toml.binds}

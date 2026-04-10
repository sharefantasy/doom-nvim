;; gentlewind.modules.langs.nix
;; Nix language support for gentlewind-nvim

(local nix {})

(set nix.settings
  {:disable_treesitter false
   :treesitter_grammars "nix"
   :disable_lsp false
   :lsp_name "nil_ls"
   :disable_formatting false
   :formatting_package "alejandra"
   :formatting_provider "builtins.formatting.alejandra"
   :formatting_config nil})

(set nix.packages {})
(set nix.configs {})

(local langs_utils (require :gentlewind.modules.langs.utils))

(set nix.autocmds
  [{:FileType :nix
    :callback (langs_utils.wrap_language_setup "nix" (fn []
                                            (when (not nix.settings.disable_lsp)
                                              (langs_utils.use_lsp_mason nix.settings.lsp_name))
                                            
                                            (when (not nix.settings.disable_treesitter)
                                              (langs_utils.use_tree_sitter nix.settings.treesitter_grammars))
                                            ))
    :once true}])

(set nix.cmds [])
(set nix.binds [])

{:packages nix.packages
 :configs nix.configs
 :settings nix.settings
 :autocmds nix.autocmds
 :cmds nix.cmds
 :binds nix.binds}

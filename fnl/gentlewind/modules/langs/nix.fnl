;; gentlewind.modules.langs.nix
;; Nix language support for gentlewind-nvim

(local nix {})

(nix.settings
  {:disable_treesitter false
   :treesitter_grammars "nix"
   :disable_lsp false
   :lsp_name "nil_ls"
   :disable_formatting false
   :formatting_package "alejandra"
   :formatting_provider "builtins.formatting.alejandra"
   :formatting_config nil})

(nix.packages {})
(nix.configs {})

(local langs_utils (require :gentlewind.modules.langs.utils))

(nix.autocmds
  [{:FileType :nix
    :callback (langs_utils.wrap_language_setup "nix" (fn []
                                            (when (not nix.settings.disable_lsp)
                                              (langs_utils.use_lsp_mason nix.settings.lsp_name))
                                            
                                            (when (not nix.settings.disable_treesitter)
                                              (langs_utils.use_tree_sitter nix.settings.treesitter_grammars))
                                            
                                            (when (not nix.settings.disable_formatting)
                                              (langs_utils.use_null_ls nix.settings.formatting_package
                                                                      nix.settings.formatting_provider
                                                                      nix.settings.formatting_config))))
    :once true}])

(nix.cmds [])
(nix.binds [])

{:packages nix.packages
 :configs nix.configs
 :settings nix.settings
 :autocmds nix.autocmds
 :cmds nix.cmds
 :binds nix.binds}
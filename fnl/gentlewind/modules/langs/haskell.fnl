;; gentlewind.modules.langs.haskell
;; Haskell language support for gentlewind-nvim

(local haskell {})

(haskell.settings
  {:disable_treesitter false
   :treesitter_grammars "haskell"
   :disable_lsp false
   :lsp_name "hls"
   :disable_formatting false
   :formatting_package "fourmolu"
   :formatting_provider "builtins.formatting.fourmolu"
   :formatting_config nil})

(haskell.packages {})
(haskell.configs {})

(local langs_utils (require :gentlewind.modules.langs.utils))

(haskell.autocmds
  [{:FileType :haskell
    :callback (langs_utils.wrap_language_setup "haskell" (fn []
                                                (when (not haskell.settings.disable_lsp)
                                                  (langs_utils.use_lsp_mason haskell.settings.lsp_name))
                                                
                                                (when (not haskell.settings.disable_treesitter)
                                                  (langs_utils.use_tree_sitter haskell.settings.treesitter_grammars))
                                                
                                                (when (not haskell.settings.disable_formatting)
                                                  (langs_utils.use_null_ls haskell.settings.formatting_package
                                                                          haskell.settings.formatting_provider
                                                                          haskell.settings.formatting_config))))
    :once true}])

(haskell.cmds [])
(haskell.binds [])

{:packages haskell.packages
 :configs haskell.configs
 :settings haskell.settings
 :autocmds haskell.autocmds
 :cmds haskell.cmds
 :binds haskell.binds}
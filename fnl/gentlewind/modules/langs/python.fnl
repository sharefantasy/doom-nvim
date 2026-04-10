;; gentlewind.modules.langs.python
;; Python language support for gentlewind-nvim

(local python {})

(set python.settings
  {:disable_treesitter false
   :treesitter_grammars "python"
   :disable_lsp false
   :lsp_name "pyright"
   :disable_formatting false
   :formatting_package "black"
   :formatting_provider "builtins.formatting.black"
   :formatting_config nil})

(set python.packages {})
(set python.configs {})

(local langs_utils (require :gentlewind.modules.langs.utils))

(set python.autocmds
  [{:FileType :python
    :callback (langs_utils.wrap_language_setup "python" (fn []
                                                (when (not python.settings.disable_lsp)
                                                  (langs_utils.use_lsp_mason python.settings.lsp_name))
                                                
                                                (when (not python.settings.disable_treesitter)
                                                  (langs_utils.use_tree_sitter python.settings.treesitter_grammars))
                                                ))
    :once true}])

(set python.cmds [])
(set python.binds [])

{:packages python.packages
 :configs python.configs
 :settings python.settings
 :autocmds python.autocmds
 :cmds python.cmds
 :binds python.binds}

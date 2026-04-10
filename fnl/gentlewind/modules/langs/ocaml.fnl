;; gentlewind.modules.langs.ocaml
;; OCaml language support for gentlewind-nvim

(local ocaml {})

(set ocaml.settings
  {:disable_treesitter false
   :treesitter_grammars "ocaml"
   :disable_lsp false
   :lsp_name "ocamllsp"
   :disable_formatting false
   :formatting_package "ocamlformat"
   :formatting_provider "builtins.formatting.ocamlformat"
   :formatting_config nil})

(set ocaml.packages {})
(set ocaml.configs {})

(local langs_utils (require :gentlewind.modules.langs.utils))

(set ocaml.autocmds
  [{:FileType :ocaml
    :callback (langs_utils.wrap_language_setup "ocaml" (fn []
                                              (when (not ocaml.settings.disable_lsp)
                                                (langs_utils.use_lsp_mason ocaml.settings.lsp_name))
                                              
                                              (when (not ocaml.settings.disable_treesitter)
                                                (langs_utils.use_tree_sitter ocaml.settings.treesitter_grammars))
                                              ))
    :once true}])

(set ocaml.cmds [])
(set ocaml.binds [])

{:packages ocaml.packages
 :configs ocaml.configs
 :settings ocaml.settings
 :autocmds ocaml.autocmds
 :cmds ocaml.cmds
 :binds ocaml.binds}

;; doom.modules.langs.ocaml
;; OCaml language support for doom-nvim

(local ocaml {})

(ocaml.settings
  {:disable_treesitter false
   :treesitter_grammars "ocaml"
   :disable_lsp false
   :lsp_name "ocamllsp"
   :disable_formatting false
   :formatting_package "ocamlformat"
   :formatting_provider "builtins.formatting.ocamlformat"
   :formatting_config nil})

(ocaml.packages {})
(ocaml.configs {})

(local langs_utils (require :doom.modules.langs.utils))

(ocaml.autocmds
  [{:FileType :ocaml
    (langs_utils.wrap_language_setup "ocaml" (fn []
                                              (when (not ocaml.settings.disable_lsp)
                                                (langs_utils.use_lsp_mason ocaml.settings.lsp_name))
                                              
                                              (when (not ocaml.settings.disable_treesitter)
                                                (langs_utils.use_tree_sitter ocaml.settings.treesitter_grammars))
                                              
                                              (when (not ocaml.settings.disable_formatting)
                                                (langs_utils.use_null_ls ocaml.settings.formatting_package
                                                                        ocaml.settings.formatting_provider
                                                                        ocaml.settings.formatting_config))))
    :once true}])

(ocaml.cmds [])
(ocaml.binds [])

{: packages ocaml.packages
 : configs ocaml.configs
 : settings ocaml.settings
 : autocmds ocaml.autocmds
 : cmds ocaml.cmds
 : binds ocaml.binds}
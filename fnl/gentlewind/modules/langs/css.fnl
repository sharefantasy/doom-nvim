;; gentlewind.modules.langs.css
;; CSS language support for gentlewind-nvim

(local css {})

(set css.settings
  {:disable_treesitter false
   :treesitter_grammars ["css" "scss" "less"]
   :disable_lsp false
   :lsp_name "cssls"
   :disable_formatting false
   :formatting_package "prettier"
   :formatting_provider "builtins.formatting.prettier"
   :formatting_config nil})

(set css.packages {})
(set css.configs {})

(local langs_utils (require :gentlewind.modules.langs.utils))

(set css.autocmds
  [{:FileType [:css :scss :less]
    :callback (langs_utils.wrap_language_setup "css" (fn []
                                            (when (not css.settings.disable_lsp)
                                              (langs_utils.use_lsp_mason css.settings.lsp_name))
                                            
                                            (when (not css.settings.disable_treesitter)
                                              (langs_utils.use_tree_sitter css.settings.treesitter_grammars))
                                            
                                            (when (not css.settings.disable_formatting)
                                              (langs_utils.use_null_ls css.settings.formatting_package
                                                                      css.settings.formatting_provider
                                                                      css.settings.formatting_config))))
    :once true}])

(set css.cmds [])
(set css.binds [])

{:packages css.packages
 :configs css.configs
 :settings css.settings
 :autocmds css.autocmds
 :cmds css.cmds
 :binds css.binds}
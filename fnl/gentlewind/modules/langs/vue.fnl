;; gentlewind.modules.langs.vue
;; Vue.js language support for gentlewind-nvim

(local vue {})

(vue.settings
  {:disable_treesitter false
   :treesitter_grammars ["vue" "javascript" "typescript"]
   :disable_lsp false
   :lsp_name "vuels"
   :disable_formatting false
   :formatting_package "prettier"
   :formatting_provider "builtins.formatting.prettier"
   :formatting_config nil})

(vue.packages {})
(vue.configs {})

(local langs_utils (require :gentlewind.modules.langs.utils))

(vue.autocmds
  [{:FileType :vue
    :callback (langs_utils.wrap_language_setup "vue" (fn []
                                            (when (not vue.settings.disable_lsp)
                                              (langs_utils.use_lsp_mason vue.settings.lsp_name))
                                            
                                            (when (not vue.settings.disable_treesitter)
                                              (langs_utils.use_tree_sitter vue.settings.treesitter_grammars))
                                            
                                            (when (not vue.settings.disable_formatting)
                                              (langs_utils.use_null_ls vue.settings.formatting_package
                                                                      vue.settings.formatting_provider
                                                                      vue.settings.formatting_config))))
    :once true}])

(vue.cmds [])
(vue.binds [])

{:packages vue.packages
 :configs vue.configs
 :settings vue.settings
 :autocmds vue.autocmds
 :cmds vue.cmds
 :binds vue.binds}
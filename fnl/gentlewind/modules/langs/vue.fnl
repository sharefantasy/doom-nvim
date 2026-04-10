;; gentlewind.modules.langs.vue
;; Vue.js language support for gentlewind-nvim

(local vue {})

(set vue.settings
  {:disable_treesitter false
   :treesitter_grammars ["vue" "javascript" "typescript"]
   :disable_lsp false
   :lsp_name "vuels"
   :disable_formatting false
   :formatting_package "prettier"
   :formatting_provider "builtins.formatting.prettier"
   :formatting_config nil})

(set vue.packages {})
(set vue.configs {})

(local langs_utils (require :gentlewind.modules.langs.utils))

(set vue.autocmds
  [{:FileType :vue
    :callback (langs_utils.wrap_language_setup "vue" (fn []
                                            (when (not vue.settings.disable_lsp)
                                              (langs_utils.use_lsp_mason vue.settings.lsp_name))
                                            
                                              (when (not vue.settings.disable_treesitter)
                                                (langs_utils.use_tree_sitter vue.settings.treesitter_grammars))
                                              ))
    :once true}])

(set vue.cmds [])
(set vue.binds [])

{:packages vue.packages
 :configs vue.configs
 :settings vue.settings
 :autocmds vue.autocmds
 :cmds vue.cmds
 :binds vue.binds}

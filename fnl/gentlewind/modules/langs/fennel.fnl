;; gentlewind.modules.langs.fennel
;; Fennel language support for gentlewind-nvim

(local fennel {})

(set fennel.settings
  {:disable_treesitter false
   :treesitter_grammars "fennel"
   :disable_lsp false
   :lsp_name "fennel_ls"
   :disable_formatting true
   :formatting_package nil
   :formatting_provider nil
   :formatting_config nil})

(set fennel.packages
  {:conjure {:repo "Olical/conjure"
              :ft [:fennel]
              :config (fn []
                        ((. (require :conjure.main) :main))
                        ((. (require :conjure.mapping) "on-filetype")))}
   :nfnl {:repo "Olical/nfnl" :ft :fennel}})

(set fennel.configs {})

(local langs_utils (require :gentlewind.modules.langs.utils))

(set fennel.autocmds
  [{:FileType :fennel
    :callback (langs_utils.wrap_language_setup "fennel" (fn []
                                                        (when (not fennel.settings.disable_lsp)
                                                          (langs_utils.use_lsp_mason fennel.settings.lsp_name))
                                                        
                                                        (when (not fennel.settings.disable_treesitter)
                                                          (langs_utils.use_tree_sitter fennel.settings.treesitter_grammars))))
    :once true}])

(set fennel.cmds [])
(set fennel.binds [])

{:packages fennel.packages
 :configs fennel.configs
 :settings fennel.settings
 :autocmds fennel.autocmds
 :cmds fennel.cmds
 :binds fennel.binds}

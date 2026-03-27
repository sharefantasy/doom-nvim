;; gentlewind.modules.langs.fennel
;; Fennel language support for gentlewind-nvim

(local fennel {})

(fennel.settings
  {:disable_treesitter false
   :treesitter_grammars "fennel"
   :disable_lsp false
   :lsp_name "fennel_ls"
   :disable_formatting true
   :formatting_package nil
   :formatting_provider nil
   :formatting_config nil})

(fennel.packages
  {:conjure {:repo "Olical/conjure"
              :ft [:fennel]
              :dependencies [:cmp-conjure]
              :config (fn []
                        ((require :conjure.main).main)
                        ((. (require :conjure.mapping) "on-filetype")))}
   :cmp-conjure {:repo "PaterJason/cmp-conjure"
                  :config (fn []
                            (local cmp (require :cmp))
                            (local config (cmp.get_config))
                            (table.insert config.sources {:name :buffer
                                                           :option {:sources [{:name :conjure}]}})
                            (cmp.setup config))}
   :nfnl {:repo "Olical/nfnl" :ft :fennel}})

(fennel.configs {})

(local langs_utils (require :gentlewind.modules.langs.utils))

(fennel.autocmds
  [{:FileType :fennel
    :callback (langs_utils.wrap_language_setup "fennel" (fn []
                                                        (when (not fennel.settings.disable_lsp)
                                                          (langs_utils.use_lsp_mason fennel.settings.lsp_name))
                                                        
                                                        (when (not fennel.settings.disable_treesitter)
                                                          (langs_utils.use_tree_sitter fennel.settings.treesitter_grammars))))
    :once true}])

(fennel.cmds [])
(fennel.binds [])

{:packages fennel.packages
 :configs fennel.configs
 :settings fennel.settings
 :autocmds fennel.autocmds
 :cmds fennel.cmds
 :binds fennel.binds}

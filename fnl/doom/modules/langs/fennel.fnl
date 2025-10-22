;; doom.modules.langs.fennel
;; Fennel language support for doom-nvim

(local fennel {})

(fennel.settings
  {:disable_treesitter false
   :treesitter_grammars "fennel"
   :disable_lsp false
   :lsp_name "fennel_language_server"
   :disable_formatting false
   :formatting_package "fnlfmt"
   :formatting_provider "builtins.formatting.fnlfmt"
   :formatting_config nil})

(fennel.packages
  {:conjure {:"Olical/conjure"
              :ft [:fennel]
              :dependencies [:cmp-conjure]
              :config (fn []
                        (require :conjure.main).main()
                        (require :conjure.mapping)["on-filetype"]())}
   :cmp-conjure {:"PaterJason/cmp-conjure"
                  :config (fn []
                            (local cmp (require :cmp))
                            (local config (cmp.get_config))
                            (table.insert config.sources {:name :buffer
                                                           :option {:sources [{:name :conjure}]}})
                            (cmp.setup config))}
   :nfnl {:"Olical/nfnl" :ft :fennel}})

(fennel.configs {})

(local langs_utils (require :doom.modules.langs.utils))

(fennel.autocmds
  [{:FileType :fennel
    (langs_utils.wrap_language_setup "fennel" (fn []
                                                (when (not fennel.settings.disable_lsp)
                                                  (langs_utils.use_lsp_mason fennel.settings.lsp_name))
                                                
                                                (when (not fennel.settings.disable_treesitter)
                                                  (langs_utils.use_tree_sitter fennel.settings.treesitter_grammars))
                                                
                                                (when (not fennel.settings.disable_formatting)
                                                  (langs_utils.use_null_ls fennel.settings.formatting_package
                                                                           fennel.settings.formatting_provider
                                                                           fennel.settings.formatting_config))))
    :once true}])

(fennel.cmds [])
(fennel.binds [])

{: packages fennel.packages
 : configs fennel.configs
 : settings fennel.settings
 : autocmds fennel.autocmds
 : cmds fennel.cmds
 : binds fennel.binds}
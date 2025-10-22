;; doom.modules.langs.thrift
;; Thrift language support for doom-nvim

(local thrift {})

(thrift.settings
  {:disable_treesitter false
   :treesitter_grammars "thrift"
   :disable_lsp false
   :lsp_name "thriftls"
   :disable_formatting true
   :formatting_package nil
   :formatting_provider nil
   :formatting_config nil})

(thrift.packages {})
(thrift.configs {})

(local langs_utils (require :doom.modules.langs.utils))

(thrift.autocmds
  [{:FileType :thrift
    (langs_utils.wrap_language_setup "thrift" (fn []
                                                  (when (not thrift.settings.disable_lsp)
                                                    (langs_utils.use_lsp_mason thrift.settings.lsp_name))
                                                  
                                                  (when (not thrift.settings.disable_treesitter)
                                                    (langs_utils.use_tree_sitter thrift.settings.treesitter_grammars))))
    :once true}])

(thrift.cmds [])
(thrift.binds [])

{: packages thrift.packages
 : configs thrift.configs
 : settings thrift.settings
 : autocmds thrift.autocmds
 : cmds thrift.cmds
 : binds thrift.binds}
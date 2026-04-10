;; gentlewind.modules.langs.sql
;; SQL language support for gentlewind-nvim

(local sql {})

(set sql.settings
  {:disable_treesitter false
   :treesitter_grammars "sql"
   :disable_lsp false
   :lsp_name "sqlls"
   :disable_formatting false
   :formatting_package "sqlfmt"
   :formatting_provider "builtins.formatting.sqlfmt"
   :formatting_config nil})

(set sql.packages {})
(set sql.configs {})

(local langs_utils (require :gentlewind.modules.langs.utils))

(set sql.autocmds
  [{:FileType :sql
    :callback (langs_utils.wrap_language_setup "sql" (fn []
                                            (when (not sql.settings.disable_lsp)
                                              (langs_utils.use_lsp_mason sql.settings.lsp_name))
                                            
                                            (when (not sql.settings.disable_treesitter)
                                              (langs_utils.use_tree_sitter sql.settings.treesitter_grammars))
                                            ))
    :once true}])

(set sql.cmds [])
(set sql.binds [])

{:packages sql.packages
 :configs sql.configs
 :settings sql.settings
 :autocmds sql.autocmds
 :cmds sql.cmds
 :binds sql.binds}

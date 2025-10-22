;; doom.modules.langs.gdscript
;; GDScript language support for doom-nvim

(local gdscript {})

(gdscript.settings
  {:disable_treesitter false
   :treesitter_grammars "gdscript"
   :disable_lsp false
   :lsp_name "gdscript"
   :disable_formatting true
   :formatting_package nil
   :formatting_provider nil
   :formatting_config nil})

(gdscript.packages {})
(gdscript.configs {})

(local langs_utils (require :doom.modules.langs.utils))

(gdscript.autocmds
  [{:FileType :gdscript
    (langs_utils.wrap_language_setup "gdscript" (fn []
                                                  (when (not gdscript.settings.disable_lsp)
                                                    (langs_utils.use_lsp_mason gdscript.settings.lsp_name))
                                                  
                                                  (when (not gdscript.settings.disable_treesitter)
                                                    (langs_utils.use_tree_sitter gdscript.settings.treesitter_grammars))))
    :once true}])

(gdscript.cmds [])
(gdscript.binds [])

{: packages gdscript.packages
 : configs gdscript.configs
 : settings gdscript.settings
 : autocmds gdscript.autocmds
 : cmds gdscript.cmds
 : binds gdscript.binds}
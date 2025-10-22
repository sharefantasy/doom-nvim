;; doom.modules.langs.lua
;; Lua language support for doom-nvim

(local lua {})

(lua.settings
  {:disable_treesitter false
   :treesitter_grammars "lua"
   :disable_lsp false
   :lsp_name "lua_ls"
   :disable_formatting false
   :formatting_package "stylua"
   :formatting_provider "builtins.formatting.stylua"
   :formatting_config nil})

(lua.packages {})
(lua.configs {})

(local langs_utils (require :doom.modules.langs.utils))

(lua.autocmds
  [{:FileType :lua
    (langs_utils.wrap_language_setup "lua" (fn []
                                              (when (not lua.settings.disable_lsp)
                                                (langs_utils.use_lsp_mason lua.settings.lsp_name))
                                              
                                              (when (not lua.settings.disable_treesitter)
                                                (langs_utils.use_tree_sitter lua.settings.treesitter_grammars))
                                              
                                              (when (not lua.settings.disable_formatting)
                                                (langs_utils.use_null_ls lua.settings.formatting_package
                                                                        lua.settings.formatting_provider
                                                                        lua.settings.formatting_config))))
    :once true}])

(lua.cmds [])
(lua.binds [])

{: packages lua.packages
 : configs lua.configs
 : settings lua.settings
 : autocmds lua.autocmds
 : cmds lua.cmds
 : binds lua.binds}
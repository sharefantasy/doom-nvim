;; gentlewind.modules.langs.lua
;; Lua language support for gentlewind-nvim

(local lua_mod {})

(lua_mod.settings
  {:disable_treesitter false
   :treesitter_grammars "lua"
   :disable_lsp false
   :lsp_name "lua_ls"
   :disable_formatting false
   :formatting_package "stylua"
   :formatting_provider "builtins.formatting.stylua"
   :formatting_config nil})

(lua_mod.packages {})
(lua_mod.configs {})

(local langs_utils (require :gentlewind.modules.langs.utils))

(lua_mod.autocmds
  [{:FileType :lua
    :callback (langs_utils.wrap_language_setup "lua" (fn []
                                              (when (not lua_mod.settings.disable_lsp)
                                                (langs_utils.use_lsp_mason lua_mod.settings.lsp_name))
                                              
                                              (when (not lua_mod.settings.disable_treesitter)
                                                (langs_utils.use_tree_sitter lua_mod.settings.treesitter_grammars))
                                              
                                              (when (not lua_mod.settings.disable_formatting)
                                                (langs_utils.use_null_ls lua_mod.settings.formatting_package
                                                                        lua_mod.settings.formatting_provider
                                                                        lua_mod.settings.formatting_config))))
    :once true}])

(lua_mod.cmds [])
(lua_mod.binds [])

{:packages lua_mod.packages
 :configs lua_mod.configs
 :settings lua_mod.settings
 :autocmds lua_mod.autocmds
 :cmds lua_mod.cmds
 :binds lua_mod.binds}

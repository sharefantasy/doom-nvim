;; doom.modules.langs.cc
;; C/C++ language support for doom-nvim

(local cc {})

(cc.settings
  {:disable_treesitter false
   :treesitter_grammars ["c" "cpp"]
   :disable_lsp false
   :lsp_name "clangd"
   :disable_formatting false
   :formatting_package "clang-format"
   :formatting_provider "builtins.formatting.clang_format"
   :formatting_config nil})

(cc.packages {})
(cc.configs {})

(local langs_utils (require :doom.modules.langs.utils))

(cc.autocmds
  [{:FileType [:c :cpp]
    (langs_utils.wrap_language_setup "cc" (fn []
                                           (when (not cc.settings.disable_lsp)
                                             (langs_utils.use_lsp_mason cc.settings.lsp_name))
                                           
                                           (when (not cc.settings.disable_treesitter)
                                             (langs_utils.use_tree_sitter cc.settings.treesitter_grammars))
                                           
                                           (when (not cc.settings.disable_formatting)
                                             (langs_utils.use_null_ls cc.settings.formatting_package
                                                                     cc.settings.formatting_provider
                                                                     cc.settings.formatting_config))))
    :once true}])

(cc.cmds [])
(cc.binds [])

{: packages cc.packages
 : configs cc.configs
 : settings cc.settings
 : autocmds cc.autocmds
 : cmds cc.cmds
 : binds cc.binds}
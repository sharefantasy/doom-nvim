;; gentlewind.modules.langs.cc
;; C/C++ language support for gentlewind-nvim

(local cc {})

(set cc.settings
  {:disable_treesitter false
   :treesitter_grammars ["c" "cpp"]
   :disable_lsp false
   :lsp_name "clangd"
   :disable_formatting false
   :formatting_package "clang-format"
   :formatting_provider "builtins.formatting.clang_format"
   :formatting_config nil})

(set cc.packages {})
(set cc.configs {})

(local langs_utils (require :gentlewind.modules.langs.utils))

(set cc.autocmds
  [{:FileType [:c :cpp]
    :callback (langs_utils.wrap_language_setup "cc" (fn []
                                           (when (not cc.settings.disable_lsp)
                                             (langs_utils.use_lsp_mason cc.settings.lsp_name))
                                           
                                          (when (not cc.settings.disable_treesitter)
                                            (langs_utils.use_tree_sitter cc.settings.treesitter_grammars))
                                          ))
    :once true}])

(set cc.cmds [])
(set cc.binds [])

{:packages cc.packages
 :configs cc.configs
 :settings cc.settings
 :autocmds cc.autocmds
 :cmds cc.cmds
 :binds cc.binds}

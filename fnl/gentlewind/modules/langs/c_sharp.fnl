;; gentlewind.modules.langs.c_sharp
;; C# language support for gentlewind-nvim

(local c_sharp {})

(c_sharp.settings
  {:disable_treesitter false
   :treesitter_grammars "c_sharp"
   :disable_lsp false
   :lsp_name "csharp_ls"
   :disable_formatting false
   :formatting_package "csharpier"
   :formatting_provider "builtins.formatting.csharpier"
   :formatting_config nil})

(c_sharp.packages {})
(c_sharp.configs {})

(local langs_utils (require :gentlewind.modules.langs.utils))

(c_sharp.autocmds
  [{:FileType :cs
    :callback (langs_utils.wrap_language_setup "c_sharp" (fn []
                                                (when (not c_sharp.settings.disable_lsp)
                                                  (langs_utils.use_lsp_mason c_sharp.settings.lsp_name))
                                                
                                                (when (not c_sharp.settings.disable_treesitter)
                                                  (langs_utils.use_tree_sitter c_sharp.settings.treesitter_grammars))
                                                
                                                (when (not c_sharp.settings.disable_formatting)
                                                  (langs_utils.use_null_ls c_sharp.settings.formatting_package
                                                                          c_sharp.settings.formatting_provider
                                                                          c_sharp.settings.formatting_config))))
    :once true}])

(c_sharp.cmds [])
(c_sharp.binds [])

{:packages c_sharp.packages
 :configs c_sharp.configs
 :settings c_sharp.settings
 :autocmds c_sharp.autocmds
 :cmds c_sharp.cmds
 :binds c_sharp.binds}
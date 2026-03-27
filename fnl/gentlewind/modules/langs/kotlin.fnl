;; gentlewind.modules.langs.kotlin
;; Kotlin language support for gentlewind-nvim

(local kotlin {})

(kotlin.settings
  {:disable_treesitter false
   :treesitter_grammars "kotlin"
   :disable_lsp false
   :lsp_name "kotlin_language_server"
   :disable_formatting false
   :formatting_package "ktlint"
   :formatting_provider "builtins.formatting.ktlint"
   :formatting_config nil})

(kotlin.packages {})
(kotlin.configs {})

(local langs_utils (require :gentlewind.modules.langs.utils))

(kotlin.autocmds
  [{:FileType :kotlin
    :callback (langs_utils.wrap_language_setup "kotlin" (fn []
                                            (when (not kotlin.settings.disable_lsp)
                                              (langs_utils.use_lsp_mason kotlin.settings.lsp_name))
                                            
                                            (when (not kotlin.settings.disable_treesitter)
                                              (langs_utils.use_tree_sitter kotlin.settings.treesitter_grammars))
                                            
                                            (when (not kotlin.settings.disable_formatting)
                                              (langs_utils.use_null_ls kotlin.settings.formatting_package
                                                                      kotlin.settings.formatting_provider
                                                                      kotlin.settings.formatting_config))))
    :once true}])

(kotlin.cmds [])
(kotlin.binds [])

{:packages kotlin.packages
 :configs kotlin.configs
 :settings kotlin.settings
 :autocmds kotlin.autocmds
 :cmds kotlin.cmds
 :binds kotlin.binds}
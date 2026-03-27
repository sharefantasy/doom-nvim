;; gentlewind.modules.langs.java
;; Java language support for gentlewind-nvim

(local java {})

(java.settings
  {:disable_treesitter false
   :treesitter_grammars "java"
   :disable_lsp false
   :lsp_name "jdtls"
   :disable_formatting false
   :formatting_package "google-java-format"
   :formatting_provider "builtins.formatting.google_java_format"
   :formatting_config nil})

(java.packages {})
(java.configs {})

(local langs_utils (require :gentlewind.modules.langs.utils))

(java.autocmds
  [{:FileType :java
    :callback (langs_utils.wrap_language_setup "java" (fn []
                                            (when (not java.settings.disable_lsp)
                                              (langs_utils.use_lsp_mason java.settings.lsp_name))
                                            
                                            (when (not java.settings.disable_treesitter)
                                              (langs_utils.use_tree_sitter java.settings.treesitter_grammars))
                                            
                                            (when (not java.settings.disable_formatting)
                                              (langs_utils.use_null_ls java.settings.formatting_package
                                                                      java.settings.formatting_provider
                                                                      java.settings.formatting_config))))
    :once true}])

(java.cmds [])
(java.binds [])

{:packages java.packages
 :configs java.configs
 :settings java.settings
 :autocmds java.autocmds
 :cmds java.cmds
 :binds java.binds}
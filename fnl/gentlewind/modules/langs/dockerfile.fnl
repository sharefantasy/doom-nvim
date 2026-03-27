;; gentlewind.modules.langs.dockerfile
;; Dockerfile language support for gentlewind-nvim

(local dockerfile {})

(dockerfile.settings
  {:disable_treesitter false
   :treesitter_grammars "dockerfile"
   :disable_lsp false
   :lsp_name "dockerls"
   :disable_formatting false
   :formatting_package "dockerfile_tools"
   :formatting_provider "builtins.formatting.dockerfile_tools"
   :formatting_config nil})

(dockerfile.packages {})
(dockerfile.configs {})

(local langs_utils (require :gentlewind.modules.langs.utils))

(dockerfile.autocmds
  [{:FileType :dockerfile
    :callback (langs_utils.wrap_language_setup "dockerfile" (fn []
                                                    (when (not dockerfile.settings.disable_lsp)
                                                      (langs_utils.use_lsp_mason dockerfile.settings.lsp_name))
                                                    
                                                    (when (not dockerfile.settings.disable_treesitter)
                                                      (langs_utils.use_tree_sitter dockerfile.settings.treesitter_grammars))
                                                    
                                                    (when (not dockerfile.settings.disable_formatting)
                                                      (langs_utils.use_null_ls dockerfile.settings.formatting_package
                                                                              dockerfile.settings.formatting_provider
                                                                              dockerfile.settings.formatting_config))))
    :once true}])

(dockerfile.cmds [])
(dockerfile.binds [])

{:packages dockerfile.packages
 :configs dockerfile.configs
 :settings dockerfile.settings
 :autocmds dockerfile.autocmds
 :cmds dockerfile.cmds
 :binds dockerfile.binds}
;; gentlewind.modules.langs.yaml
;; YAML language support for gentlewind-nvim

(local yaml {})

(yaml.settings
  {:disable_treesitter false
   :treesitter_grammars "yaml"
   :disable_lsp false
   :lsp_name "yamlls"
   :disable_formatting false
   :formatting_package "prettier"
   :formatting_provider "builtins.formatting.prettier"
   :formatting_config nil})

(yaml.packages {})
(yaml.configs {})

(local langs_utils (require :gentlewind.modules.langs.utils))

(yaml.autocmds
  [{:FileType :yaml
    :callback (langs_utils.wrap_language_setup "yaml" (fn []
                                            (when (not yaml.settings.disable_lsp)
                                              (langs_utils.use_lsp_mason yaml.settings.lsp_name))
                                            
                                            (when (not yaml.settings.disable_treesitter)
                                              (langs_utils.use_tree_sitter yaml.settings.treesitter_grammars))
                                            
                                            (when (not yaml.settings.disable_formatting)
                                              (langs_utils.use_null_ls yaml.settings.formatting_package
                                                                      yaml.settings.formatting_provider
                                                                      yaml.settings.formatting_config))))
    :once true}])

(yaml.cmds [])
(yaml.binds [])

{:packages yaml.packages
 :configs yaml.configs
 :settings yaml.settings
 :autocmds yaml.autocmds
 :cmds yaml.cmds
 :binds yaml.binds}
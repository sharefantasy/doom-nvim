;; gentlewind.modules.langs.terraform
;; Terraform language support for gentlewind-nvim

(local terraform {})

(set terraform.settings
  {:disable_treesitter false
   :treesitter_grammars "terraform"
   :disable_lsp false
   :lsp_name "terraformls"
   :disable_formatting false
   :formatting_package "terraform_fmt"
   :formatting_provider "builtins.formatting.terraform_fmt"
   :formatting_config nil})

(set terraform.packages {})
(set terraform.configs {})

(local langs_utils (require :gentlewind.modules.langs.utils))

(set terraform.autocmds
  [{:FileType :terraform
    :callback (langs_utils.wrap_language_setup "terraform" (fn []
                                                  (when (not terraform.settings.disable_lsp)
                                                    (langs_utils.use_lsp_mason terraform.settings.lsp_name))
                                                  
                                                  (when (not terraform.settings.disable_treesitter)
                                                    (langs_utils.use_tree_sitter terraform.settings.treesitter_grammars))
                                                  
                                                  (when (not terraform.settings.disable_formatting)
                                                    (langs_utils.use_null_ls terraform.settings.formatting_package
                                                                            terraform.settings.formatting_provider
                                                                            terraform.settings.formatting_config))))
    :once true}])

(set terraform.cmds [])
(set terraform.binds [])

{:packages terraform.packages
 :configs terraform.configs
 :settings terraform.settings
 :autocmds terraform.autocmds
 :cmds terraform.cmds
 :binds terraform.binds}
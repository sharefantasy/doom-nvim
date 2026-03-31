;; gentlewind.modules.langs.tailwindcss
;; Tailwind CSS language support for gentlewind-nvim

(local tailwindcss {})

(set tailwindcss.settings
  {:disable_treesitter false
   :treesitter_grammars ["html" "css" "scss" "javascript" "typescript" "tsx"]
   :disable_lsp false
   :lsp_name "tailwindcss"
   :disable_formatting false
   :formatting_package "prettier"
   :formatting_provider "builtins.formatting.prettier"
   :formatting_config nil})

(set tailwindcss.packages {})
(set tailwindcss.configs {})

(local langs_utils (require :gentlewind.modules.langs.utils))

(set tailwindcss.autocmds
  [{:FileType [:html :css :scss :javascript :typescript :tsx :vue :svelte]
    :callback (langs_utils.wrap_language_setup "tailwindcss" (fn []
                                                      (when (not tailwindcss.settings.disable_lsp)
                                                        (langs_utils.use_lsp_mason tailwindcss.settings.lsp_name))
                                                      
                                                      (when (not tailwindcss.settings.disable_treesitter)
                                                        (langs_utils.use_tree_sitter tailwindcss.settings.treesitter_grammars))
                                                      
                                                      (when (not tailwindcss.settings.disable_formatting)
                                                        (langs_utils.use_null_ls tailwindcss.settings.formatting_package
                                                                                tailwindcss.settings.formatting_provider
                                                                                tailwindcss.settings.formatting_config))))
    :once true}])

(set tailwindcss.cmds [])
(set tailwindcss.binds [])

{:packages tailwindcss.packages
 :configs tailwindcss.configs
 :settings tailwindcss.settings
 :autocmds tailwindcss.autocmds
 :cmds tailwindcss.cmds
 :binds tailwindcss.binds}
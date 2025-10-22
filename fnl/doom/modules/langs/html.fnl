;; doom.modules.langs.html
;; HTML/CSS language support for doom-nvim

(local html {})

(html.settings
  {:disable_treesitter false
   :treesitter_grammars ["html" "css" "scss"]
   :disable_lsp false
   :lsp_name "html"
   :disable_formatting false
   :formatting_package "prettier"
   :formatting_provider "builtins.formatting.prettier"
   :formatting_config nil})

(html.packages {})
(html.configs {})

(local langs_utils (require :doom.modules.langs.utils))

(html.autocmds
  [{:FileType [:html :css :scss]
    (langs_utils.wrap_language_setup "html" (fn []
                                            (when (not html.settings.disable_lsp)
                                              (langs_utils.use_lsp_mason html.settings.lsp_name))
                                            
                                            (when (not html.settings.disable_treesitter)
                                              (langs_utils.use_tree_sitter html.settings.treesitter_grammars))
                                            
                                            (when (not html.settings.disable_formatting)
                                              (langs_utils.use_null_ls html.settings.formatting_package
                                                                      html.settings.formatting_provider
                                                                      html.settings.formatting_config))))
    :once true}])

(html.cmds [])
(html.binds [])

{: packages html.packages
 : configs html.configs
 : settings html.settings
 : autocmds html.autocmds
 : cmds html.cmds
 : binds html.binds}
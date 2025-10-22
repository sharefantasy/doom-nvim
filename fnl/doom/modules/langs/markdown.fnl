;; doom.modules.langs.markdown
;; Markdown language support for doom-nvim

(local markdown {})

(markdown.settings
  {:disable_treesitter false
   :treesitter_grammars "markdown"
   :disable_lsp false
   :lsp_name "marksman"
   :disable_formatting false
   :formatting_package "prettier"
   :formatting_provider "builtins.formatting.prettier"
   :formatting_config nil})

(markdown.packages
  {:markdown-preview {:"iamcco/markdown-preview.nvim"
                        :build (fn [] (vim.fn["mkdp#util#install"]))
                        :config (fn []
                                  (vim.g.mkdp_filetypes {:markdown})})}})

(markdown.configs {})

(local langs_utils (require :doom.modules.langs.utils))

(markdown.autocmds
  [{:FileType :markdown
    (langs_utils.wrap_language_setup "markdown" (fn []
                                                  (when (not markdown.settings.disable_lsp)
                                                    (langs_utils.use_lsp_mason markdown.settings.lsp_name))
                                                  
                                                  (when (not markdown.settings.disable_treesitter)
                                                    (langs_utils.use_tree_sitter markdown.settings.treesitter_grammars))
                                                  
                                                  (when (not markdown.settings.disable_formatting)
                                                    (langs_utils.use_null_ls markdown.settings.formatting_package
                                                                            markdown.settings.formatting_provider
                                                                            markdown.settings.formatting_config))))
    :once true}])

(markdown.cmds
  [["MarkdownPreview"]
   (fn []
     (vim.fn["mkdp#util#start_preview"]))
   {:desc "Start markdown preview"}])

(markdown.binds
  [{:n {:keybinds
        [{:["<leader>m"] {:name "+markdown"
                            :p (vim.fn["mkdp#util#start_preview"])
                            :s (vim.fn["mkdp#util#stop_preview"])}}]}}])

{: packages markdown.packages
 : configs markdown.configs
 : settings markdown.settings
 : autocmds markdown.autocmds
 : cmds markdown.cmds
 : binds markdown.binds}
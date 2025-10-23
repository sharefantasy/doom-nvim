;; doom.modules.langs.markdown
;; Markdown language support for doom-nvim

(local markdown {})

(set markdown.settings
  {:disable_treesitter false
   :treesitter_grammars "markdown"
   :disable_lsp false
   :lsp_name "marksman"
   :disable_formatting false
   :formatting_package "prettier"
   :formatting_provider "builtins.formatting.prettier"
   :formatting_config nil})

(set markdown.packages
  {:markdown-preview {"repo" "iamcco/markdown-preview.nvim"
                        "build" (fn [] (_G.vim.fn ["mkdp#util#install"]))
                        "config" (fn []
                                  (set _G.vim.g.mkdp_filetypes [:markdown]))}})

(set markdown.configs {})

(set markdown.autocmds [])

(set markdown.cmds
  [["MarkdownPreview"]
   (fn []
     (_G.vim.fn ["mkdp#util#start_preview"]))
   {:desc "Start markdown preview"}])

(set markdown.binds
  {:n {:keybinds
        ["<leader>m" {:group "+markdown"}
         "<leader>mp" {:desc "Start preview" :cmd (fn [] (_G.vim.fn ["mkdp#util#start_preview"]))}
         "<leader>ms" {:desc "Stop preview" :cmd (fn [] (_G.vim.fn ["mkdp#util#stop_preview"]))}]}})

{"packages" markdown.packages
 "configs" markdown.configs
 "settings" markdown.settings
 "autocmds" markdown.autocmds
 "cmds" markdown.cmds
 "binds" markdown.binds}
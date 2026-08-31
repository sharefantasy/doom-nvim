;; gentlewind.modules.langs.markdown
;; Markdown language support for gentlewind-nvim

(local markdown {})

(set markdown.settings
  {:disable_treesitter false
   :treesitter_grammars ["markdown" "markdown_inline" "html" "yaml" "latex"]
   :disable_lsp false
   :lsp_name "marksman"
   :disable_formatting false
   :formatting_package "prettier"
   :formatting_provider "builtins.formatting.prettier"
   :formatting_config nil})

(set markdown.packages
  {:markdown-preview {:repo "iamcco/markdown-preview.nvim"
                      :ft ["markdown"]
                      :cmd ["MarkdownPreview" "MarkdownPreviewStop" "MarkdownPreviewToggle"]
                      :build (fn [] (_G.vim.fn ["mkdp#util#install"]))
                      :config (fn []
                                (set _G.vim.g.mkdp_filetypes [:markdown])
                                (set _G.vim.g.mkdp_theme "dark")
                                (set _G.vim.g.mkdp_echo_preview_url 1)
                                (set _G.vim.g.mkdp_preview_options
                                  {:disable_sync_scroll 0
                                   :sync_scroll_type "middle"
                                   :hide_yaml_meta 1
                                   :disable_filename 0
                                   :maid {:theme "dark"}
                                   :uml {:server "https://www.plantuml.com/plantuml"
                                         :imageFormat "svg"}}))}
   :md-render {:repo "delphinus/md-render.nvim"
               :version "*"
               :ft ["markdown"]
               :cmd ["MdRender"]
               :dependencies ["nvim-tree/nvim-web-devicons"
                              "delphinus/budoux.lua"]}})

(set markdown.configs {})

(set markdown.autocmds [])

(set markdown.cmds [])

(set markdown.binds
  {:<leader>m {:name "+文档"
               :p {:desc "开预览" :cmd (fn [] (pcall vim.cmd "MarkdownPreview"))}
               :s {:desc "关预览" :cmd (fn [] (pcall vim.cmd "MarkdownPreviewStop"))}
               :v {:desc "内嵌预览" :cmd (fn [] (pcall vim.cmd "MdRender"))}
               :b {:desc "浏览模式" :cmd (fn [] (pcall vim.cmd "MdRender toggle"))}
               :t {:desc "标签预览" :cmd (fn [] (pcall vim.cmd "MdRender tab"))}
               :d {:desc "分屏预览" :cmd (fn [] (pcall vim.cmd "vert MdRender split"))}}})

{"packages" markdown.packages
 "configs" markdown.configs
 "settings" markdown.settings
 "autocmds" markdown.autocmds
 "cmds" markdown.cmds
 "binds" markdown.binds}

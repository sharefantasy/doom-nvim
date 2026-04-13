;; gentlewind.modules.langs.go
;; Go language support for gentlewind-nvim

(local go {})

(set go.settings
  {:disable_treesitter false
   :treesitter_grammars "go"
   :disable_lsp false
   :lsp_name "gopls"
   :disable_formatting false
   :formatting_package "gofumpt"
   :formatting_provider "builtins.formatting.gofumpt"
   :formatting_config nil})

(set go.packages
  {:go-nvim
   {:repo "ray-x/go.nvim"
    :dependencies ["neovim/nvim-lspconfig"]
    :ft ["go" "gomod" "gosum" "gowork" "gotmpl"]
    :config (fn []
              ;; go.nvim 内部用 vim.cmd([[multi-line vimscript]]) 定义 autocmd，
              ;; 但 vim.cmd 默认不支持多行脚本（会触发 E216）。这里对 go.nvim setup 做一次局部兼容。
              (local orig-cmd vim.cmd)
              (set vim.cmd
                   (fn [x]
                     (if (and (= (type x) :string)
                              (string.find x "\n" 1 true))
                         (vim.api.nvim_exec2 x {:output false})
                         (orig-cmd x))))
                (let [packed [(pcall (fn []
                                    ((. (require :go) :setup)
                                     {:lsp_cfg false  ;; Use mason-lspconfig instead
                                      :lsp_gofumpt true
                                      ;; lsp_cfg=false 时 go.nvim 不负责启动 LSP，因此 lsp_on_attach 会被忽略并输出警告。
                                      ;; LSP 的 on_attach/键位等由 gentlewind 的 LspAttach 统一处理。
                                      })))
                            ]
                    ok (. packed 1)
                    err (. packed 2)]
                (set vim.cmd orig-cmd)
                (when (not ok)
                  (vim.notify (.. "go.nvim setup 失败：" err) vim.log.levels.ERROR))))}})

(set go.configs {})

(local langs_utils (require :gentlewind.modules.langs.utils))

(set go.autocmds
  [{:FileType :go
    :callback (langs_utils.wrap_language_setup
               "go"
               (fn []
                 (when (not go.settings.disable_lsp)
                   (langs_utils.use_lsp_mason go.settings.lsp_name))
                 (when (not go.settings.disable_treesitter)
                   (langs_utils.use_tree_sitter go.settings.treesitter_grammars))))
    :once true}])

(set go.cmds [])
(set go.binds [])

{:packages go.packages
 :configs go.configs
 :settings go.settings
 :autocmds go.autocmds
 :cmds go.cmds
 :binds go.binds}

;; gentlewind.modules.langs.utils
;; Language utilities for gentlewind-nvim

(local utils {})

(fn utils.wrap_language_setup [lang callback]
  "Wrap language setup with proper error handling"
  (fn []
    (let [packed [(pcall callback)]
          ok (. packed 1)
          err (. packed 2)]
      (when (not ok)
        (vim.notify (.. "Error setting up " lang " language support: " err) vim.log.levels.ERROR)))))

(fn utils.use_lsp_mason [server-name]
  "Use LSP server via Mason"
  (local mason_lspconfig (require :mason-lspconfig))
  (mason_lspconfig.setup {:ensure_installed [server-name]}))

(fn utils.use_tree_sitter [grammars]
  "Use tree-sitter grammar"
  (local ts (require :nvim-treesitter.configs))
  (ts.setup {:ensure_installed grammars}))

{:wrap_language_setup utils.wrap_language_setup
 :use_lsp_mason utils.use_lsp_mason
 :use_tree_sitter utils.use_tree_sitter
 }

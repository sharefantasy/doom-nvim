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
  (when (not utils.settings.disable_lsp)
    (local mason_lspconfig (require :mason-lspconfig))
    (mason_lspconfig.setup {:ensure_installed [server-name]})))

(fn utils.use_tree_sitter [grammars]
  "Use tree-sitter grammar"
  (when (not utils.settings.disable_treesitter)
    (local ts (require :nvim-treesitter.configs))
    (ts.setup {:ensure_installed grammars})))

(fn utils.use_null_ls [package provider config]
  "Use null-ls for formatting/linting"
  (when (not utils.settings.disable_formatting)
    (local null_ls (require :null-ls))
    (local sources (require provider))
    (null_ls.setup {:sources (if config
                                 (config sources)
                                 [sources])})))

{:wrap_language_setup utils.wrap_language_setup
 :use_lsp_mason utils.use_lsp_mason
 :use_tree_sitter utils.use_tree_sitter
 :use_null_ls utils.use_null_ls}

;; doom.modules.langs.rust
;; Rust language support for doom-nvim

(local rust {})

(rust.settings
  {:disable_treesitter false
   :treesitter_grammars "rust"
   :disable_lsp false
   :lsp_name "rust_analyzer"
   :disable_formatting false
   :formatting_package "rustfmt"
   :formatting_provider "builtins.formatting.rustfmt"
   :formatting_config nil})

(rust.packages
  {:rust-tools {:"simrat39/rust-tools.nvim"
                 :dependencies [:lspconfig]
                 :config (fn []
                           (local rust-tools (require :rust-tools))
                           (rust-tools.setup {:server {:on_attach (fn [client bufnr]
                                                                      ;; Enable inlay hints
                                                                      (rust-tools.inlay_hints.enable))))}})
   :lspconfig {:"neovim/nvim-lspconfig"}})

(rust.configs {})

(local langs_utils (require :doom.modules.langs.utils))

(rust.autocmds
  [{:FileType :rust
    (langs_utils.wrap_language_setup "rust" (fn []
                                              (when (not rust.settings.disable_lsp)
                                                (langs_utils.use_lsp_mason rust.settings.lsp_name))
                                              
                                              (when (not rust.settings.disable_treesitter)
                                                (langs_utils.use_tree_sitter rust.settings.treesitter_grammars))
                                              
                                              (when (not rust.settings.disable_formatting)
                                                (langs_utils.use_null_ls rust.settings.formatting_package
                                                                        rust.settings.formatting_provider
                                                                        rust.settings.formatting_config))))
    :once true}])

(rust.cmds [])
(rust.binds [])

{: packages rust.packages
 : configs rust.configs
 : settings rust.settings
 : autocmds rust.autocmds
 : cmds rust.cmds
 : binds rust.binds}
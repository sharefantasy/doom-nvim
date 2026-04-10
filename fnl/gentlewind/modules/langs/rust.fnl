;; gentlewind.modules.langs.rust
;; Rust language support for gentlewind-nvim

(local rust {})

(set rust.settings
  {:disable_treesitter false
   :treesitter_grammars "rust"
   :disable_lsp false
   :lsp_name "rust_analyzer"
   :disable_formatting false
   :formatting_package "rustfmt"
   :formatting_provider "builtins.formatting.rustfmt"
   :formatting_config nil})

(set rust.packages
  {:rust-tools {:repo "simrat39/rust-tools.nvim"
                 :dependencies ["neovim/nvim-lspconfig"]
                 :ft ["rust"]
                :config (fn []
                          (local rust-tools (require :rust-tools))
                          (rust-tools.setup {:server {:on_attach (fn [client bufnr]
                                          ;; Enable inlay hints
                                          (rust-tools.inlay_hints.enable))}}))}
   :lspconfig {:repo "neovim/nvim-lspconfig"}})

(set rust.configs {})

(local langs_utils (require :gentlewind.modules.langs.utils))

(set rust.autocmds
  [{:FileType :rust
    :callback (langs_utils.wrap_language_setup "rust" (fn []
                                              (when (not rust.settings.disable_lsp)
                                                (langs_utils.use_lsp_mason rust.settings.lsp_name))
                                              
                                              (when (not rust.settings.disable_treesitter)
                                                (langs_utils.use_tree_sitter rust.settings.treesitter_grammars))
                                              ))
    :once true}])

(set rust.cmds [])
(set rust.binds [])

{:packages rust.packages
 :configs rust.configs
 :settings rust.settings
 :autocmds rust.autocmds
 :cmds rust.cmds
 :binds rust.binds}

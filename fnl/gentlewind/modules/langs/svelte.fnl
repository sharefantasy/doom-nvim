;; gentlewind.modules.langs.svelte
;; Svelte language support for gentlewind-nvim

(local svelte {})

(set svelte.settings
  {:disable_treesitter false
   :treesitter_grammars ["svelte" "javascript" "typescript"]
   :disable_lsp false
   :lsp_name "svelte"
   :disable_formatting false
   :formatting_package "prettier"
   :formatting_provider "builtins.formatting.prettier"
   :formatting_config nil})

(set svelte.packages {})
(set svelte.configs {})

(local langs_utils (require :gentlewind.modules.langs.utils))

(set svelte.autocmds
  [{:FileType :svelte
    :callback (langs_utils.wrap_language_setup "svelte" (fn []
                                                (when (not svelte.settings.disable_lsp)
                                                  (langs_utils.use_lsp_mason svelte.settings.lsp_name))
                                                
                                                (when (not svelte.settings.disable_treesitter)
                                                  (langs_utils.use_tree_sitter svelte.settings.treesitter_grammars))
                                                
                                                (when (not svelte.settings.disable_formatting)
                                                  (langs_utils.use_null_ls svelte.settings.formatting_package
                                                                          svelte.settings.formatting_provider
                                                                          svelte.settings.formatting_config))))
    :once true}])

(set svelte.cmds [])
(set svelte.binds [])

{:packages svelte.packages
 :configs svelte.configs
 :settings svelte.settings
 :autocmds svelte.autocmds
 :cmds svelte.cmds
 :binds svelte.binds}
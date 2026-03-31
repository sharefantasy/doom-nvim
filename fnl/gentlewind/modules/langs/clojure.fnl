;; gentlewind.modules.langs.clojure
;; Clojure language support for gentlewind-nvim

(local clojure {})

(set clojure.settings
  {:disable_treesitter false
   :treesitter_grammars "clojure"
   :disable_lsp false
   :lsp_name "clojure_lsp"
   :disable_formatting false
   :formatting_package "cljfmt"
   :formatting_provider "builtins.formatting.cljfmt"
   :formatting_config nil})

(set clojure.packages
  {:conjure {:repo "Olical/conjure"
              :ft [:clojure]
              :dependencies [:cmp-conjure]
              :config (fn []
                        ((. (require :conjure.main) :main))
                        ((. (require :conjure.mapping) "on-filetype")))}
   :cmp-conjure {:repo "PaterJason/cmp-conjure"
                  :config (fn []
                            (local cmp (require :cmp))
                            (local config (cmp.get_config))
                            (table.insert config.sources {:name :buffer
                                                           :option {:sources [{:name :conjure}]}})
                            (cmp.setup config))}})

(set clojure.configs {})

(local langs_utils (require :gentlewind.modules.langs.utils))

(set clojure.autocmds
  [{:FileType :clojure
    :callback (langs_utils.wrap_language_setup "clojure" (fn []
                                                (when (not clojure.settings.disable_lsp)
                                                  (langs_utils.use_lsp_mason clojure.settings.lsp_name))
                                                
                                                (when (not clojure.settings.disable_treesitter)
                                                  (langs_utils.use_tree_sitter clojure.settings.treesitter_grammars))
                                                
                                                (when (not clojure.settings.disable_formatting)
                                                  (langs_utils.use_null_ls clojure.settings.formatting_package
                                                                          clojure.settings.formatting_provider
                                                                          clojure.settings.formatting_config))))
    :once true}])

(set clojure.cmds [])
(set clojure.binds [])

{:packages clojure.packages
 :configs clojure.configs
 :settings clojure.settings
 :autocmds clojure.autocmds
 :cmds clojure.cmds
 :binds clojure.binds}

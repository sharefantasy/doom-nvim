;; doom.modules.core.treesitter
;; Treesitter module for doom-nvim

(local treesitter {})

(treesitter.packages
  {:nvim-treesitter {:"nvim-treesitter/nvim-treesitter"
                     :build ":TSUpdate"
                     :config (fn []
                               (require :nvim-treesitter.configs).setup
                                 {:highlight {:enable true
                                             :disable ["markdown"]}  ;; 禁用markdown避免E5248错误
                                  :indent {:enable true}
                                  :incremental_selection {:enable true}
                                  :textobjects {:enable true
                                               :select {:disable ["markdown"]}}))}})

(treesitter.configs {})
(treesitter.settings {})
(treesitter.autocmds [])
(treesitter.cmds [])
(treesitter.binds [])

{: packages treesitter.packages
 : configs treesitter.configs
 : settings treesitter.settings
 : autocmds treesitter.autocmds
 : cmds treesitter.cmds
 : binds treesitter.binds}
;; gentlewind.modules.core.treesitter
;; Treesitter module for gentlewind-nvim

(local treesitter {})

(treesitter.packages
  {:nvim-treesitter {:repo "nvim-treesitter/nvim-treesitter"
                     :build ":TSUpdate"
                     :config (fn []
                               ((require :nvim-treesitter.configs).setup
                                 {:highlight {:enable true
                                              :disable ["markdown"]}
                                  :indent {:enable true}
                                  :incremental_selection {:enable true}
                                  :textobjects {:enable true
                                                :select {:disable ["markdown"]}}}))}})

(treesitter.configs {})
(treesitter.settings {:show_compiler_warning_message false})
(treesitter.autocmds [])
(treesitter.cmds [])
(treesitter.binds [])

{:packages treesitter.packages
 :configs treesitter.configs
 :settings treesitter.settings
 :autocmds treesitter.autocmds
 :cmds treesitter.cmds
 :binds treesitter.binds}

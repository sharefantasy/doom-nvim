;; gentlewind.modules.core.treesitter
;; Treesitter module for gentlewind-nvim

(local treesitter {})

(set treesitter.packages
  {:nvim-treesitter {:repo "nvim-treesitter/nvim-treesitter"
                     :branch "main"
                     :build ":TSUpdate"
                     :config (fn []
                               ((. (require :nvim-treesitter) :setup) {}))}})

(set treesitter.configs {})
(set treesitter.settings {:show_compiler_warning_message false})
(set treesitter.autocmds [])
(set treesitter.cmds [])
(set treesitter.binds [])

{:packages treesitter.packages
 :configs treesitter.configs
 :settings treesitter.settings
 :autocmds treesitter.autocmds
 :cmds treesitter.cmds
 :binds treesitter.binds}

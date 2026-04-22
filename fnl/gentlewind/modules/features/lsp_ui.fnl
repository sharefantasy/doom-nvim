;; gentlewind.modules.features.lsp_ui
;; LSP UI enhancements and LSP lifecycle management

(local M {})

(set M.packages
  {:lightbulb {:repo "kosayoda/nvim-lightbulb"
               :event "LspAttach"
               :opts {:autocmd {:enabled true}}}

   :eagle {:repo "soulis-1256/eagle.nvim"
           :cmd ["EagleWin"]
           :opts {}}

   :garbage-day {:repo "Zeioth/garbage-day.nvim"
                 :event "VeryLazy"
                 :opts {:notifications false}}})

(set M.binds {})
(set M.cmds [])
(set M.autocmds [])
(set M.configs {})
(set M.settings {})

{:packages M.packages
 :configs M.configs
 :settings M.settings
 :autocmds M.autocmds
 :cmds M.cmds
 :binds M.binds}


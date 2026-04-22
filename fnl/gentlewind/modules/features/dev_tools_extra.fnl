;; gentlewind.modules.features.dev_tools_extra
;; Developer tools that extend code actions / test workflows

(local M {})

(set M.packages
  {:dev-tools {:repo "yarospace/dev-tools.nvim"
               :event "LspAttach"
               :dependencies ["nvim-treesitter/nvim-treesitter" "folke/snacks.nvim"]
               :opts {:ui {:override true
                           :group_actions true}}}

   :coverage {:repo "andythigpen/nvim-coverage"
              :cmd ["Coverage" "CoverageLoad" "CoverageShow" "CoverageHide" "CoverageToggle"]
              :dependencies ["nvim-lua/plenary.nvim"]
              :opts {:auto_reload true}}})

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


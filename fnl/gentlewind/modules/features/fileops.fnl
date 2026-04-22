;; gentlewind.modules.features.fileops
;; File operations & navigation helpers (Oil / Genghis / Brewfile)

(local M {})

(set M.packages
  {:oil {:repo "stevearc/oil.nvim"
         :cmd ["Oil"]
         :dependencies ["echasnovski/mini.icons" "nvim-tree/nvim-web-devicons"]
         :opts {}}

   :genghis {:repo "chrisgrieser/nvim-genghis"
             :cmd ["Genghis"]
             :dependencies ["folke/snacks.nvim"]
             :opts {}}

   :brewfile {:repo "piersolenski/brewfile.nvim"
              :cmd ["Brewfile"]
              :opts {}}})

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


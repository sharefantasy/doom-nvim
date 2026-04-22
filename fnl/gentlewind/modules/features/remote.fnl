;; gentlewind.modules.features.remote
;; Remote/Container development helpers

(local M {})

(set M.packages
  {:distant {:repo "chipsenkbeil/distant.nvim"
             :branch "v0.3"
             :cmd ["DistantInstall" "DistantClientVersion" "DistantConnect"]
             :config (fn []
                       (pcall (fn [] ((. (require :distant) :setup))))) }

   :devcontainer {:repo "esensar/nvim-dev-container"
                  :cmd ["DevcontainerStart" "DevcontainerAttach" "DevcontainerExec"
                        "DevcontainerStop" "DevcontainerStopAll" "DevcontainerRemoveAll"
                        "DevcontainerLogs" "DevcontainerEditNearestConfig"]
                  :dependencies ["nvim-treesitter/nvim-treesitter"]
                  :opts {}}})

;; Keymaps are wired from user/config.fnl (leader groups)
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


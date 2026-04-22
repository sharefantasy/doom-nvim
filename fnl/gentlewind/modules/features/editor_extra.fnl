;; gentlewind.modules.features.editor_extra
;; Small editor QoL plugins (warp / hodur / toggleword / time-machine)

(local M {})

(set M.packages
  {:warp {:repo "nolleh/warp.nvim"
          :cmd ["Warp"]
          :config (fn []
                    (pcall (fn [] ((. (require :warp) :setup) {:default_keymap false}))))}

   :hodur {:repo "vodchella/hodur.nvim"
           :config (fn []
                     ;; 默认 Ctrl-G，可在 user/config.fnl 里覆盖
                     (pcall (fn [] ((. (require :hodur) :setup) {:key "<C-g>"}))))}

   :toggleword {:repo "iquzart/toggleword.nvim"
                :config (fn []
                          (pcall (fn [] ((. (require :toggleword) :setup) {:key "<leader>tt"}))))}

   :time-machine {:repo "y3owk1n/time-machine.nvim"
                  :cmd ["TimeMachineToggle" "TimeMachinePurgeBuffer" "TimeMachinePurgeAll"
                        "TimeMachineLogShow" "TimeMachineLogClear"]
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

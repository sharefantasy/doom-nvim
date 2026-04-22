;; gentlewind.modules.features.db_extra
;; Database helpers (dadbod-grip)

(local M {})

(set M.packages
  {:dadbod-grip {:repo "joryeugene/dadbod-grip.nvim"
                 :version "*"
                 :cmd ["Grip"
                       "GripStart"
                       "GripHome"
                       "GripConnect"
                       "GripSchema"
                       "GripTables"
                       "GripQuery"
                       "GripSave"
                       "GripLoad"
                       "GripHistory"
                       "GripProfile"
                       "GripExplain"
                       "GripAsk"
                       "GripDiff"
                       "GripCreate"
                       "GripDrop"
                       "GripRename"
                       "GripProperties"
                       "GripExport"
                       "GripAttach"
                       "GripDetach"
                       "GripOpen"]
                 :dependencies ["folke/snacks.nvim"]
                 :opts {:picker "snacks"
                        :completion false}}})

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

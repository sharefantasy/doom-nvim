;; gentlewind.modules.core.nest
;; Nest keybinding module for gentlewind-nvim

(local nest {})

(set nest.packages {:nest-nvim "connorgmeehan/nest.nvim"})

(set nest.configs
  {:nest-nvim
   (fn []
     (local nest (require :nest))
     (nest.setup {:disable_keymaps_in_macro true
                  :disable_keymaps_in_operator_pending_mode true}))})

(set nest.settings {})
(set nest.autocmds [])
(set nest.cmds [])
(set nest.binds [])

{:packages nest.packages
 :configs nest.configs
 :settings nest.settings
 :autocmds nest.autocmds
 :cmds nest.cmds
 :binds nest.binds}

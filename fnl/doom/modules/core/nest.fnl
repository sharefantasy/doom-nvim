;; doom.modules.core.nest
;; Nest keybinding module for doom-nvim

(local nest {})

(nest.packages {:nest-nvim "connorgmeehan/nest.nvim"})

(nest.configs
  {:nest-nvim
   (fn []
     (local nest (require :nest))
     (nest.setup {:disable_keymaps_in_macro true
                  :disable_keymaps_in_operator_pending_mode true}))})

(nest.settings {})
(nest.autocmds [])
(nest.cmds [])
(nest.binds [])

{: packages nest.packages
 : configs nest.configs
 : settings nest.settings
 : autocmds nest.autocmds
 : cmds nest.cmds
 : binds nest.binds}
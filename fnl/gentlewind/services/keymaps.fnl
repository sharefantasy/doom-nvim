;; gentlewind.services.keymaps
;; Keymap management service for gentlewind-nvim

(local keymaps_service {})

(fn keymaps_service.applyKeymaps [keymaps]
  "Apply a list of keymaps using nest.nvim style"
  (when keymaps
    (local nest (require :nest))
    (nest.applyKeymaps keymaps)))

(fn keymaps_service.set [mode lhs rhs opts]
  "Set a single keymap"
  (local options (or opts {}))
  (vim.keymap.set mode lhs rhs options))

{:applyKeymaps
 :set}
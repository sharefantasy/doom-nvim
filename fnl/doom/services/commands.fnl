;; doom.services.commands
;; Command management service for doom-nvim

(local commands_service {})

(fn commands_service.set [name cmd opts]
  "Create a user command"
  (local options (or opts {}))
  (vim.api.nvim_create_user_command name cmd options))

{: set}
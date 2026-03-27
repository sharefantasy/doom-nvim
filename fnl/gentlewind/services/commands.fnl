;; gentlewind.services.commands
;; Command management service for gentlewind-nvim

(local commands_service {})

(local utils (require :gentlewind.utils))

;; Data to be stored globally so it can be accessed from the nvim-0.5 implementation
(local data (or _G._gentlewind_commands_service_data {:command_actions {}}))
(set _G._gentlewind_commands_service_data data)

(local set-command-implementations
  {"nvim-0.5" (fn [name command opts]
                ;; Build the command constructor
                (var cmd-string "command! ")
                (when (and opts (not= nil opts.nargs))
                  (set cmd-string (.. cmd-string (string.format "-nargs=%s " opts.nargs))))
                (when (and opts (not= nil opts.completion))
                  (set cmd-string
                       (.. cmd-string
                           (string.format "-complete=%s " (table.concat opts.complete ",")))))
                (set cmd-string (.. cmd-string " " name " "))
                (if (= "string" (type command))
                  (set cmd-string (.. cmd-string command " "))
                  (do
                    (local uid (utils.unique_index))
                    (set (. data.command_actions uid) command)
                    (set cmd-string
                         (.. cmd-string
                             (string.format "lua _gentlewind_commands_service_data.command_actions[%d]" uid)))
                    (if (not= nil opts.nargs)
                      (set cmd-string (.. cmd-string "(<f-args>)"))
                      (set cmd-string (.. cmd-string "()")))))
                (vim.cmd cmd-string))
   "nvim-0.8" (fn [name command opts]
                (vim.api.nvim_create_user_command name command opts))})

(local set-command-fn (utils.pick_compatible_field set-command-implementations))

(local del-command-implementations
  {"nvim-0.5" (fn [name] (vim.cmd (string.format "delcommand %s" name)))
   "nvim-0.8" (fn [name] (vim.api.nvim_del_user_command name))})

(local del-command-fn (utils.pick_compatible_field del-command-implementations))

(set commands_service.stored_names {})

(fn normalize-name [name]
  (if (and (= (type name) "table") (not (empty? name)) (= (type (. name 1)) "string"))
    (. name 1)
    name))

(fn commands_service.set [name command opts]
  "Create a user command"
  (local normalized (normalize-name name))
  (set (. commands_service.stored_names normalized) true)
  (set-command-fn normalized command (or opts {})))

(fn commands_service.del [name]
  (local normalized (normalize-name name))
  (set (. commands_service.stored_names normalized) nil)
  (del-command-fn normalized))

(fn commands_service.del_all []
  (each [name _ (pairs commands_service.stored_names)]
    (when name (del-command-fn name)))
  (set commands_service.stored_names {}))

{:set commands_service.set
 :del commands_service.del
 :del_all commands_service.del_all}

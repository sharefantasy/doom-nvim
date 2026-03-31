;; gentlewind.modules.core.reloader
;; Module reloader for development

(local reloader {})

(set reloader.packages {})
(set reloader.configs {})
(set reloader.settings {})
(set reloader.autocmds [])
(set reloader.cmds [])
(set reloader.binds [])

;; Auto-reload configuration on save
(table.insert reloader.autocmds
              ["BufWritePost" "*.fnl"
               (fn []
                 (vim.notify "Fennel file saved, reloading..." vim.log.levels.INFO)
                 ;; Could add auto-compilation here
                 )])

{:packages reloader.packages
 :configs reloader.configs
 :settings reloader.settings
 :autocmds reloader.autocmds
 :cmds reloader.cmds
 :binds reloader.binds}
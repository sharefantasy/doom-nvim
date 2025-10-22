;; doom.modules.core.reloader
;; Module reloader for development

(local reloader {})

(reloader.packages {})
(reloader.configs {})
(reloader.settings {})
(reloader.autocmds [])
(reloader.cmds [])
(reloader.binds [])

;; Auto-reload configuration on save
(table.insert reloader.autocmds
              ["BufWritePost" "*.fnl"
               (fn []
                 (vim.notify "Fennel file saved, reloading..." vim.log.levels.INFO)
                 ;; Could add auto-compilation here
                 )])

{: packages reloader.packages
 : configs reloader.configs
 : settings reloader.settings
 : autocmds reloader.autocmds
 : cmds reloader.cmds
 : binds reloader.binds}
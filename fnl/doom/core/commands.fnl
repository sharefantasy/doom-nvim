;; doom.core.commands
;; Core commands for doom-nvim

(local commands (require :doom.services.commands))

;; Doom check updates command
(commands.set "DoomCheckUpdates"
              (fn []
                (when doom.core.updater
                  (doom.core.updater.check_updates false)))
              {:desc "Check for Doom Nvim updates"})

;; Doom reload command
(commands.set "DoomReload"
              (fn []
                (vim.cmd "luafile %")
                (vim.notify "Doom configuration reloaded" vim.log.levels.INFO))
              {:desc "Reload Doom configuration"})

;; Doom version command
(commands.set "DoomVersion"
              (fn []
                (vim.notify (.. "Doom Nvim v" (doom.version or "unknown")) vim.log.levels.INFO))
              {:desc "Show Doom Nvim version"})
;; gentlewind.core.commands
;; Core commands for gentlewind-nvim

(local commands (require :gentlewind.services.commands))

;; Gentlewind check updates command
(commands.set "GentlewindCheckUpdates"
              (fn []
                (when gentlewind.core.updater
                  (gentlewind.core.updater.check_updates false)))
              {:desc "Check for Gentlewind Nvim updates"})

;; Gentlewind reload command
(commands.set "GentlewindReload"
              (fn []
                (vim.cmd "luafile %")
                (vim.notify "Gentlewind configuration reloaded" vim.log.levels.INFO))
              {:desc "Reload Gentlewind configuration"})

;; Gentlewind version command
(commands.set "GentlewindVersion"
              (fn []
                (vim.notify (.. "Gentlewind Nvim v" (or gentlewind.version "unknown")) vim.log.levels.INFO))
              {:desc "Show Gentlewind Nvim version"})

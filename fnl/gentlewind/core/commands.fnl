;; gentlewind.core.commands
;; Core commands for gentlewind-nvim

(local commands (require :gentlewind.core.utils))

;; Gentlewind check updates command
(commands.set_command "GentlewindCheckUpdates"
              (fn []
                (when gentlewind.core.updater
                  (gentlewind.core.updater.check_updates false)))
              {:desc "Check for Gentlewind Nvim updates"})

;; Gentlewind reload command
(commands.set_command "GentlewindReload"
              (fn []
                (vim.cmd "luafile %")
                (vim.notify "Gentlewind configuration reloaded" vim.log.levels.INFO))
              {:desc "Reload Gentlewind configuration"})

;; Gentlewind version command
(commands.set_command "GentlewindVersion"
              (fn []
                (vim.notify (.. "Gentlewind Nvim v" (or gentlewind.version "unknown")) vim.log.levels.INFO))
              {:desc "Show Gentlewind Nvim version"})

;; doom.core.init
;; Entrypoint for the doom-nvim framework written in Fennel

;; Disable vim builtins for faster startup time
(local g vim.g)

(set g.loaded_gzip 1)
(set g.loaded_zip 1)
(set g.loaded_zipPlugin 1)
(set g.loaded_tar 1)
(set g.loaded_tarPlugin 1)

(set g.loaded_getscript 1)
(set g.loaded_getscriptPlugin 1)
(set g.loaded_vimball 1)
(set g.loaded_vimballPlugin 1)
(set g.loaded_2html_plugin 1)

(set g.loaded_matchit 1)
(set g.loaded_matchparen 1)
(set g.loaded_logiPat 1)
(set g.loaded_rrhelper 1)

(local profiler (require :doom.services.profiler))

;; Sets the `doom` global object
(profiler.start "framework|doom.core.doom_global")
(require :doom.core.doom_global)
(profiler.stop "framework|doom.core.doom_global")

(profiler.start "framework|doom.utils")
(local utils (require :doom.utils))
(profiler.stop "framework|doom.utils")

;; Boostraps the doom-nvim framework, runs the user's `config.lua` file.
(profiler.start "framework|doom.core.config (setup + user)")
(local config (utils.safe_require :doom.core.config))
(config.load)
(profiler.stop "framework|doom.core.config (setup + user)")

(when (not (utils.is_module_enabled "features" "netrw"))
  (set g.loaded_netrw 1)
  (set g.loaded_netrwPlugin 1)
  (set g.loaded_netrwSettings 1)
  (set g.loaded_netrwFileHandlers 1))

;; Set some extra commands
(utils.safe_require :doom.core.commands)

(profiler.start "framework|doom.core.modules")
;; Load Doom modules.
(local modules (utils.safe_require :doom.core.modules))
(profiler.start "framework|init enabled modules")
(modules.load_modules)
(profiler.stop "framework|init enabled modules")
(profiler.start "framework|user settings")
(modules.handle_user_config)
(profiler.stop "framework|user settings")
(modules.try_sync)
(modules.handle_lazynvim)
(profiler.stop "framework|doom.core.modules")

;; Load the colourscheme
(profiler.start "framework|doom.core.ui")
(utils.safe_require :doom.core.ui)
(profiler.stop "framework|doom.core.ui")

;; Execute autocommand for user to hook custom config into
(vim.api.nvim_exec_autocmds :User {:pattern "DoomStarted"})
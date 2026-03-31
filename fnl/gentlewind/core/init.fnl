;; gentlewind.core.init
;; Entrypoint for the gentlewind-nvim framework written in Fennel

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

(local profiler (require :gentlewind.core.utils))

;; Sets the `gentlewind` global object
(profiler.start "framework|gentlewind.core.gentlewind_global")
(require :gentlewind.core.gentlewind_global)
(profiler.stop "framework|gentlewind.core.gentlewind_global")

(profiler.start "framework|gentlewind.utils")
(local utils (require :gentlewind.utils))
(profiler.stop "framework|gentlewind.utils")

;; Boostraps the gentlewind-nvim framework, runs the user's `config.lua` file.
(profiler.start "framework|gentlewind.core.config (setup + user)")
(local config (utils.safe_require :gentlewind.core.config))
(when config
  (config.load))
(when (not config)
  (vim.notify "Failed to load gentlewind.core.config" vim.log.levels.ERROR))
(profiler.stop "framework|gentlewind.core.config (setup + user)")

(when (not (utils.is_module_enabled "features" "netrw"))
  (set g.loaded_netrw 1)
  (set g.loaded_netrwPlugin 1)
  (set g.loaded_netrwSettings 1)
  (set g.loaded_netrwFileHandlers 1))

;; Set some extra commands
(utils.safe_require :gentlewind.core.commands)

(profiler.start "framework|gentlewind.core.modules")
;; Load Gentlewind modules.
(local modules (utils.safe_require :gentlewind.core.modules))
(when modules
  (profiler.start "framework|init enabled modules")
  (modules.load_modules)
  (profiler.stop "framework|init enabled modules")
  (profiler.start "framework|user settings")
  (modules.handle_user_config)
  (profiler.stop "framework|user settings")
  (modules.try_sync)
  (modules.handle_lazynvim))
(when (not modules)
  (vim.notify "Failed to load gentlewind.core.modules" vim.log.levels.ERROR))
(profiler.stop "framework|gentlewind.core.modules")

;; Load the colourscheme
(profiler.start "framework|gentlewind.core.ui")
(utils.safe_require :gentlewind.core.ui)
(profiler.stop "framework|gentlewind.core.ui")

;; Execute autocommand for user to hook custom config into
(vim.api.nvim_exec_autocmds :User {:pattern "GentlewindStarted"})

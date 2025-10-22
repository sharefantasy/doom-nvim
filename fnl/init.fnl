;; init.fnl - Main entry point for Aniseed-based Doom Nvim
;; This replaces the original init.lua

;; Check if user is running Doom in a supported Neovim version
(when (not= (vim.fn.has "nvim-0.7.0") 1)
  (local message (table.concat ["You are using an unsupported version of Neovim."
                                ""
                                "Doom nvim and many of its plugins require at least version 0.7.0 to work as expected."
                                "Consider updating if you run into issues."
                                "https://github.com/doom-neovim/doom-nvim/blob/main/docs/updating-neovim.md"] "\n"))
  (vim.notify message vim.log.levels.ERROR))

;; Configure Aniseed
(module {...
         :autoload true
         :compile-path "lua"
         :fnl-path "fnl"})

;; Load the profiler
(local profiler (require :doom.services.profiler))
(profiler.start "framework|init.fnl")

;; Preload lazy.nvim
(local lazypath (.. (vim.fn.stdpath :data) "/lazy/lazy.nvim"))
(when (not (vim.loop.fs_stat lazypath))
  (print "Bootstrapping lazy.nvim, please wait...")
  (vim.fn.system ["git" "clone" "--filter=blob:none"
                  "https://github.com/folke/lazy.nvim.git" "--branch=stable"
                  lazypath]))
(vim.opt.rtp:prepend lazypath)

;; Make sure ~/.local/share/nvim exists
(vim.fn.mkdir (vim.fn.stdpath :data) "p")

;; Add ~/.local/share to runtimepath early
(vim.opt.runtimepath:append (vim.fn.stdpath :data))

;; Load the doom-nvim framework
(require :doom.core)

;; Check for updates
(vim.defer_fn (fn []
                (when (and doom.check_updates doom.core.updater)
                  (doom.core.updater.check_updates true)))
              1)

(profiler.stop "framework|init.fnl")
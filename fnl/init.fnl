;; init.fnl - Main entry point for Aniseed-based Gentlewind Nam
;; This replaces the original init.lua

;; Check if user is running Gentlewind in a supported Neovim version
(when (not= (vim.fn.has "nvim-0.7.0") 1)
  (local message (table.concat ["You are using an unsupported version of Neovim."
                                ""
                                "Gentlewind nvim and many of its plugins require at least version 0.7.0 to work as expected."
                                "Consider updating if you run into issues."
                                "https://github.com/gentlewind-neovim/gentlewind-nvim/blob/main/docs/updating-neovim.md"] "\n"))
  (vim.notify message vim.log.levels.ERROR))

;; Configure Aniseed
(module
  {:autoload true
   :compile-path "lua"
   :fnl-path "fnl"})

;; Load the profiler
(local profiler (require :gentlewind.services.profiler))
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

;; Sanitize group names (augroup / highlight) to avoid E5248 on invalid characters
(let [orig-create-augroup vim.api.nvim_create_augroup
      orig-set-hl vim.api.nvim_set_hl]
  (fn sanitize-group-name [name]
    (let [name (if (= (type name) :string) name (tostring name))
          sanitized (string.gsub name "[^%w_]" "_")]
      sanitized))
  (set vim.api.nvim_create_augroup (fn [name opts]
                                    (orig-create-augroup (sanitize-group-name name) opts)))
  (set vim.api.nvim_set_hl orig-set-hl))

;; Load the gentlewind-nvim framework
(require :gentlewind.core)

;; Check for updates
(vim.defer_fn (fn []
                (when (and gentlewind.check_updates gentlewind.core.updater)
                  (gentlewind.core.updater.check_updates true)))
              1)

(profiler.stop "framework|init.fnl")

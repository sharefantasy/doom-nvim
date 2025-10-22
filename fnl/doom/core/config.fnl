;; doom.core.config
;; Responsible for setting vim global defaults, managing doom config options,
;; pre-configuring user modules from modules.lua, and running user's config.lua

(local profiler (require :doom.services.profiler))
(local utils (require :doom.utils))

(local config {})
(local filename "config.lua")

(set config.source nil)

;; Entry point to bootstrap doom-nvim.
(fn config.load []
  ;; Set vim defaults on first load
  (set vim.opt.hidden true)
  (set vim.opt.updatetime 200)
  (set vim.opt.timeoutlen 400)
  (set vim.opt.background "dark")
  (set vim.opt.completeopt ["menu" "menuone" "preview" "noinsert" "noselect"])
  (set vim.opt.shortmess "atsc")
  (set vim.opt.inccommand "split")
  (set vim.opt.path "**")
  (set vim.opt.signcolumn "auto:2-3")
  (set vim.opt.foldcolumn "auto:9")
  (set vim.opt.formatoptions:append "j")
  (set vim.opt.fillchars {:vert "▕"
                           :fold " "
                           :eob " "
                           :diff "─"
                           :msgsep "‾"
                           :foldopen "▾"
                           :foldclose "▸"
                           :foldsep "│"})
  (set vim.opt.smartindent true)
  (set vim.opt.copyindent true)
  (set vim.opt.preserveindent true)
  (set vim.opt.cursorline true)
  (set vim.opt.splitright false)
  (set vim.opt.splitbelow true)
  (set vim.opt.scrolloff 4)
  (set vim.opt.showmode false)
  (set vim.opt.mouse "a")
  (set vim.opt.wrap false)
  (set vim.opt.swapfile false)
  (set vim.opt.expandtab true)
  (set vim.opt.conceallevel 0)
  (set vim.opt.foldenable true)
  (set vim.opt.foldtext ((require :doom.core.functions).sugar_folds))

  ;; Combine enabled modules (modules.lua) with core modules
  (local enabled_modules (require :doom.core.modules).enabled_modules)

  (profiler.start "framework|import modules")
  ;; Iterate over each module and save it to the doom global object
  (each [section_name section_modules (pairs enabled_modules)]
    (each [_, module_name (ipairs section_modules)]
      ;; If the section is `user` resolves from `lua/user/modules`
      (local profiler_message (.. "modules|import `" section_name "." module_name "`"))
      (profiler.start profiler_message)
      (local search_paths [(.. "user.modules." section_name "." module_name)
                           (.. "doom.modules." section_name "." module_name)])

      (local log (require :doom.utils.logging))
      (local ok result final-err)
      (each [_, path (ipairs search_paths)]
        (when (not ok)
          (set ok result (xpcall require #(set final-err $) path))
          (when ok (break))))
      
      (if ok
          (set doom[section_name][module_name] result)
          (log.error
           (string.format "There was an error loading module '%s.%s'. Traceback:\n%s"
                          section_name module_name (debug.traceback final-err))))
      (profiler.stop profiler_message)))
  (profiler.stop "framework|import modules")

  (profiler.start "framework|config.lua (user)")
  ;; Execute user's `config.lua` so they can modify the doom global object
  (local ok err (xpcall dofile debug.traceback config.source))
  (local log (require :doom.utils.logging))
  (when (and (not ok) err)
    (log.error (.. "Error while running `config.lua. Traceback:\n" err)))
  (profiler.stop "framework|config.lua (user)")

  ;; Apply the necessary `doom.field_name` options
  (set vim.opt.shiftwidth doom.indent)
  (set vim.opt.softtabstop doom.indent)
  (set vim.opt.tabstop doom.indent)
  
  (when doom.guicolors
    (if (= (vim.fn.exists "+termguicolors") 1)
        (set vim.opt.termguicolors true)
        (= (vim.fn.exists "+guicolors") 1)
        (set vim.opt.guicolors true)))

  (when doom.auto_comment
    (vim.opt.formatoptions:append "croj"))
  
  (when doom.movement_wrap
    (vim.cmd "set whichwrap+=<,>,[,],h,l"))

  (if doom.undo_dir
      (do (set vim.opt.undofile true)
          (set vim.opt.undodir doom.undo_dir))
      (do (set vim.opt.undofile false)
          (set vim.opt.undodir nil)))

  (when doom.global_statusline
    (set vim.opt.laststatus 3))

  ;; Use system clipboard
  (when doom.clipboard
    (set vim.opt.clipboard "unnamedplus"))

  (if doom.ignorecase
      (vim.cmd "set ignorecase")
      (vim.cmd "set noignorecase"))
  
  (if doom.smartcase
      (vim.cmd "set smartcase")
      (vim.cmd "set nosmartcase"))

  ;; Color column
  (set vim.opt.colorcolumn (if (= (type doom.max_columns) :number)
                               (tostring doom.max_columns)
                               ""))

  ;; Number column
  (set vim.opt.number (not doom.disable_numbering))
  (set vim.opt.relativenumber (and (not doom.disable_numbering) doom.relative_num))

  (set vim.g.mapleader doom.leader_key))

;; Path cases:
;;   1. stdpath('config')/../doom-nvim/config.lua
;;   2. stdpath('config')/config.lua
;;   3. <runtimepath>/doom-nvim/config.lua
(set config.source (utils.find_config filename))

config
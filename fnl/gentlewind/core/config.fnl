;; gentlewind.core.config
;; Responsible for setting vim global defaults, managing gentlewind config options,
;; pre-configuring user modules from modules.lua, and running user's config.lua

(local profiler (require :gentlewind.core.utils))
(local utils (require :gentlewind.utils))

(local config {})
(local filename "config.lua")

(set config.source nil)

;; Entry point to bootstrap gentlewind-nvim.
(fn config.load []
  (when (not gentlewind)
    (set _G.gentlewind {}))
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
  (: vim.opt.formatoptions :append "j")
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
  (set vim.opt.foldtext "v:lua.gentlewind_sugar_folds")

  ;; Combine enabled modules (modules.lua) with core modules
  (local enabled_modules (. (require :gentlewind.core.modules) :enabled_modules))

  (profiler.start "framework|import modules")
  ;; Iterate over each module and save it to the gentlewind global object
  (each [section_name section_modules (pairs enabled_modules)]
    (each [_ module_name (ipairs section_modules)]
      ;; If the section is `user` resolves from `lua/user/modules`
      (local profiler_message (.. "modules|import `" section_name "." module_name "`"))
      (profiler.start profiler_message)
      (local search_paths [(.. "user.modules." section_name "." module_name)
                           (.. "gentlewind.modules." section_name "." module_name)])

      (local log (. (require :gentlewind.utils) :logging))
      (var ok nil)
      (var result nil)
      (var final-err nil)
      (var done false)
      (each [_ path (ipairs search_paths)]
        (when (and (not done) (not ok))
          (let [packed [(pcall require path)]
                success (. packed 1)
                res (. packed 2)]
            (set ok success)
            (set result res)
            (when (not ok)
              (set final-err res))
            (when ok (set done true)))))
      
      (if ok
          (do
            (when (not (. gentlewind section_name))
              (tset gentlewind section_name {}))
            (tset (. gentlewind section_name) module_name result))
          (log.error
           (string.format "There was an error loading module '%s.%s'. Traceback:\n%s"
                          section_name module_name (debug.traceback final-err))))
      (profiler.stop profiler_message)))
  (profiler.stop "framework|import modules")

  (profiler.start "framework|config.lua (user)")
  ;; Execute user's `config.lua` so they can modify the gentlewind global object
  (let [packed [(xpcall dofile debug.traceback config.source)]
        ok (. packed 1)
        err (. packed 2)]
    (local log (. (require :gentlewind.utils) :logging))
    (when (and (not ok) err)
      (log.error (.. "Error while running `config.lua. Traceback:\n" err))))
  (profiler.stop "framework|config.lua (user)")

  ;; Apply the necessary `gentlewind.field_name` options
  (set vim.opt.shiftwidth gentlewind.indent)
  (set vim.opt.softtabstop gentlewind.indent)
  (set vim.opt.tabstop gentlewind.indent)
  
  (when gentlewind.guicolors
    (if (= (vim.fn.exists "+termguicolors") 1)
        (set vim.opt.termguicolors true)
        (= (vim.fn.exists "+guicolors") 1)
        (set vim.opt.guicolors true)))

  (when gentlewind.auto_comment
    (: vim.opt.formatoptions :append "croj"))
  
  (when gentlewind.movement_wrap
    (vim.cmd "set whichwrap+=<,>,[,],h,l"))

  (if gentlewind.undo_dir
      (do (set vim.opt.undofile true)
          (set vim.opt.undodir gentlewind.undo_dir))
      (do (set vim.opt.undofile false)
          (set vim.opt.undodir nil)))

  (when gentlewind.global_statusline
    (set vim.opt.laststatus 3))

  ;; Use system clipboard
  (when gentlewind.clipboard
    (set vim.opt.clipboard "unnamedplus"))

  (if gentlewind.ignorecase
      (vim.cmd "set ignorecase")
      (vim.cmd "set noignorecase"))
  
  (if gentlewind.smartcase
      (vim.cmd "set smartcase")
      (vim.cmd "set nosmartcase"))

  ;; Color column
  (set vim.opt.colorcolumn (if (= (type gentlewind.max_columns) :number)
                               (tostring gentlewind.max_columns)
                               ""))

  ;; Number column
  (set vim.opt.number (not gentlewind.disable_numbering))
  (set vim.opt.relativenumber (and (not gentlewind.disable_numbering) gentlewind.relative_num))

  (set vim.g.mapleader gentlewind.leader_key))

;; Path cases:
;;   1. stdpath('config')/../gentlewind-nvim/config.lua
;;   2. stdpath('config')/config.lua
;;   3. <runtimepath>/gentlewind-nvim/config.lua
(set config.source (utils.find_config filename))

config

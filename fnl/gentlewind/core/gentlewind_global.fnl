;; gentlewind.core.gentlewind_global
;; Sets up the global gentlewind object and configuration

;; Create the global gentlewind object with default configuration
(set _G.gentlewind
      {:freeze_dependencies false
       :logging "info"
       :indent 2
       :guicolors true
       :auto_comment true
       :movement_wrap false
       :undo_dir nil
       :global_statusline false
       :clipboard true
       :ignorecase true
       :smartcase true
       :max_columns nil
       :disable_numbering false
       :relative_num false
       ;; 注意：这里要用真实空格，不要用 "<Space>" 字符串，否则 <leader> 会展开成字面量 "<Space>"
       :leader_key " "
       :check_updates true
       :colorscheme "gentlewind-one"
       :packages []
       :modules {:core {}
                 :features {}
                 :langs {}}
       :cmds {}
       :autocmds {}
       :binds []
       :use_package nil
       :use_keybind nil
       :use_autocmd nil
       :use_cmd nil})

;; Set up helper functions for gentlewind global
(fn normalize-package [pkg]
  (if (= (type pkg) :table)
    (do
      (local repo (or (. pkg :repo) (. pkg "repo")))
      (when (and repo (not (. pkg 1)))
        (tset pkg 1 repo)
        (tset pkg :repo nil)
        (tset pkg "repo" nil))
      pkg)
    pkg))

(fn gentlewind.use_package [...]
  "Add packages to gentlewind's package list"
  (each [_ pkg (ipairs [...])]
    (table.insert gentlewind.packages (normalize-package pkg))))

(fn gentlewind.use_keybind [...]
  "Add keybinds to gentlewind's keybind list"
  (each [_ bind (ipairs [...])]
    (table.insert gentlewind.binds bind)))

(fn gentlewind.use_autocmd [...]
  "Add autocommands to gentlewind's autocmd list"
  (each [_ autocmd (ipairs [...])]
    (table.insert gentlewind.autocmds autocmd)))

(fn gentlewind.use_cmd [...]
  "Add commands to gentlewind's command list"
  (each [_ cmd (ipairs [...])]
    (table.insert gentlewind.cmds cmd)))

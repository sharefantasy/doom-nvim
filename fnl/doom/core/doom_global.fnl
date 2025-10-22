;; doom.core.doom_global
;; Sets up the global doom object and configuration

;; Create the global doom object with default configuration
(set _G.doom
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
       :leader_key "<Space>"
       :check_updates true
       :colorscheme "doom-one"
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

;; Set up helper functions for doom global
(fn doom.use_package [...]
  "Add packages to doom's package list"
  (each [_, pkg (ipairs [...])]
    (table.insert doom.packages pkg)))

(fn doom.use_keybind [...]
  "Add keybinds to doom's keybind list"
  (each [_, bind (ipairs [...])]
    (table.insert doom.binds bind)))

(fn doom.use_autocmd [...]
  "Add autocommands to doom's autocmd list"
  (each [_, autocmd (ipairs [...])]
    (table.insert doom.autocmds autocmd)))

(fn doom.use_cmd [...]
  "Add commands to doom's command list"
  (each [_, cmd (ipairs [...])]
    (table.insert doom.cmds cmd)))
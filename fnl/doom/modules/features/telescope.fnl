;; doom.modules.features.telescope
;; Fuzzy finder for doom-nvim

(local telescope {})

;; Package definitions
(set telescope.packages
  {:telescope {"repo" "nvim-telescope/telescope.nvim"
               "dependencies" ["nvim-lua/plenary.nvim" "nvim-telescope/telescope-fzf-native.nvim"]
               "config" (fn []
                          (local telescope (require :telescope))
                          (telescope.setup
                            {:defaults {:mappings {:i {"<C-u>" false
                                                       "<C-d>" false}}}})
                          (telescope.load_extension :fzf))}
   :plenary {"repo" "nvim-lua/plenary.nvim"}
   :telescope-fzf-native {"repo" "nvim-telescope/telescope-fzf-native.nvim"
                          "build" "make"
                          "cond" (fn [] (_G.vim.fn.executable "make") :eq 1)}})

;; Module configurations
(set telescope.configs {})

;; Module settings
(set telescope.settings
  {:telescope_buffer_ignore [:term://*]
   :telescope_files_ignore ["%.jpg" "%.jpeg" "%.png" "%.svg" "%.otf" "%.ttf" 
                             "%.woff" "%.woff2" "%.gif" "%.mp4" "%.mp3" "%.m4a" 
                             "%.ogg" "%.flac" "%.pdf" "%.zip" "%.tar" "%.gz" 
                             "%.rar" "%.7z" "%.bz2" "%.xz" "%.deb" "%.rpm" 
                             "%.msi" "%.phar" "%.vsix" "%.apk" "%.dmg"]})

;; Autocommands
(set telescope.autocmds [])

;; Commands
(set telescope.cmds
  [["Telescope"
    (fn [opts]
      (. (require :telescope.builtin) :builtin opts))
    {:desc "内置搜"}])

;; Key bindings - using new which-key format
(set telescope.binds
  {:n {:keybinds
        ["<leader>f" {:name "+搜索"}
         "<leader>ff" {:desc "找文件" :cmd (fn [] (. (require :telescope.builtin) :find_files))}
         "<leader>fr" {:desc "最近" :cmd (fn [] (. (require :telescope.builtin) :recent_files))}
         "<leader>fg" {:desc "全文搜" :cmd (fn [] (. (require :telescope.builtin) :live_grep))}
         "<leader>fb" {:desc "缓冲" :cmd (fn [] (. (require :telescope.builtin) :buffers))}
         "<leader>fh" {:desc "帮助" :cmd (fn [] (. (require :telescope.builtin) :help_tags))}]}})

{"packages" telescope.packages
 "configs" telescope.configs
 "settings" telescope.settings
 "autocmds" telescope.autocmds
 "cmds" telescope.cmds
 "binds" telescope.binds}

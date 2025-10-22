;; doom.modules.features.telescope
;; Fuzzy finder for doom-nvim

(local telescope {})

(telescope.packages
  {:telescope {:"nvim-telescope/telescope.nvim"
                :dependencies [:plenary :telescope-fzf-native]
                :config (fn []
                          (local telescope (require :telescope))
                          (telescope.setup
                            {:defaults {:mappings {:i {:["<C-u>"] false
                                                       :["<C-d>"] false}}}})
                          (telescope.load_extension :fzf))}
   :plenary {:"nvim-lua/plenary.nvim"}
   :telescope-fzf-native {:"nvim-telescope/telescope-fzf-native.nvim"
                          :build "make"
                          :cond (fn [] (vim.fn.executable "make") :eq 1)}})

(telescope.configs {})

(telescope.settings
  {:telescope_buffer_ignore [:term://*]
   :telescope_files_ignore ["%.jpg" "%.jpeg" "%.png" "%.svg" "%.otf" "%.ttf" "%.woff" "%.woff2" "%.gif" "%.mp4" "%.mp3" "%.m4a" "%.ogg" "%.flac" "%.pdf" "%.zip" "%.tar" "%.gz" "%.rar" "%.7z" "%.bz2" "%.xz" "%.deb" "%.rpm" "%.msi" "%.phar" "%.vsix" "%.apk" "%.dmg"]})

(telescope.autocmds [])

(telescope.cmds
  [["Telescope"]
   (fn [opts]
     (require :telescope.builtin).builtin opts)
   {:desc "Open Telescope builtin picker"}])

(telescope.binds
  [{:n {:keybinds
        [{:["<leader>f"] {:name "+find"
                            :f {:name "+file"
                                :f (require :telescope.builtin).find_files
                                :r (require :telescope.builtin).recent_files
                                :g (require :telescope.builtin).live_grep
                                :b (require :telescope.builtin).buffers
                                :h (require :telescope.builtin).help_tags}}}}]}])

{: packages telescope.packages
 : configs telescope.configs
 : settings telescope.settings
 : autocmds telescope.autocmds
 : cmds telescope.cmds
 : binds telescope.binds}
;; gentlewind.modules.features.git_extra
;; Extra git helpers (search / blame / inline diff / plugin url updater)

(local M {})

(set M.packages
  {:advanced-git-search {:repo "aaronhallaert/advanced-git-search.nvim"
                         :cmd ["AdvancedGitSearch"]
                         :dependencies ["nvim-telescope/telescope.nvim"
                                        "tpope/vim-fugitive"
                                        "tpope/vim-rhubarb"
                                        "folke/snacks.nvim"]
                         :opts {}}

   :git-blame {:repo "f-person/git-blame.nvim"
               :cmd ["GitBlameToggle" "GitBlameEnable" "GitBlameDisable"
                     "GitBlameOpenCommitURL" "GitBlameCopySHA" "GitBlameCopyCommitURL"
                     "GitBlameCopyPRURL" "GitBlameOpenFileURL" "GitBlameCopyFileURL"]
               :init (fn []
                       ;; 默认关闭，按需开启
                       (set vim.g.gitblame_enabled 0))}

   :inlinediff {:repo "YouSame2/inlinediff-nvim"
                :cmd ["InlineDiff"]
                :opts {}}

   :lazyurl {:repo "cxwx/lazyUrlUpdate.nvim"
             :cmd ["LazyUrlUpdate" "LazyUrlBuild" "LazyUrlShort" "LazyUrlOpen" "LazyUrlOpenChrome"]
             :opts {}}})

(set M.binds {})
(set M.cmds [])
(set M.autocmds [])
(set M.configs {})
(set M.settings {})

{:packages M.packages
 :configs M.configs
 :settings M.settings
 :autocmds M.autocmds
 :cmds M.cmds
 :binds M.binds}


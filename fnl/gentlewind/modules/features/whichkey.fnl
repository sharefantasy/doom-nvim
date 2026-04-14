;; gentlewind.modules.features.whichkey
;; Key binding popup for gentlewind-nvim

(local whichkey {})

(set whichkey.packages
  {:which-key {:repo "folke/which-key.nvim"
                :dependencies ["echasnovski/mini.icons"
                               "nvim-tree/nvim-web-devicons"]
                :config (fn []
                          (local wk (require :which-key))
                          ;; opts.window 已废弃，使用 opts.win
                          (local t-leader ["<leader>"])
                          (tset t-leader :mode "nxso")
                          (local t-local [","])
                          (tset t-local :mode "nxso")
                          (local t-g ["g"])
                          (tset t-g :mode "n")
                          (wk.setup {:win {:padding [1 1 1 1]}
                                     :layout {:height {:min 4 :max 25}}
                                     ;; 显式设置触发键：<leader>(Space) 与 g
                                     :triggers [t-leader t-local t-g]
                                     :plugins {:presets {:operators false
                                                          :motions false
                                                          :text_objects false
                                                          :windows false
                                                          :nav false
                                                          :z false
                                                          :g true
                                                          :marks false
                                                          :registers false
                                                          :spelling false}}
                                      :notify true})

                          ;; 可选：初始化 mini.icons，提升 keymap icon 质量
                          (pcall (fn []
                                   ((. (require :mini.icons) :setup) {})))
                          ;; which-key v3 uses wk.add() for the new spec
                          (local leader ["<leader>"])
                          (tset leader :group "+leader")
                          (wk.add [leader]))}})

(set whichkey.configs {})
(set whichkey.settings {})
(set whichkey.autocmds [])
(set whichkey.cmds [])
(set whichkey.binds [])

{:packages whichkey.packages
 :configs whichkey.configs
 :settings whichkey.settings
 :autocmds whichkey.autocmds
 :cmds whichkey.cmds
 :binds whichkey.binds}

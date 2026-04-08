;; gentlewind.modules.features.whichkey
;; Key binding popup for gentlewind-nvim

(local whichkey {})

(set whichkey.packages
  {:which-key {:repo "folke/which-key.nvim"
                :config (fn []
                          (local wk (require :which-key))
                          (wk.setup {:window {:margin [1 0 1 0]
                                             :padding [1 1 1 1]}
                                     :layout {:height {:min 4 :max 25}}
                                     :plugins {:presets {:operators false
                                                          :motions false
                                                          :text_objects false
                                                          :windows false
                                                          :nav false
                                                          :z false
                                                          :g false
                                                          :marks false
                                                          :registers false
                                                          :spelling false}}
                                     :notify true})
                          ;; 注册 leader key 到 which-key
                          (wk.register {:name "+leader"} {:prefix "<leader>"}))}})

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
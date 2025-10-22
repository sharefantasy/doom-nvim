;; doom.modules.features.whichkey
;; Key binding popup for doom-nvim

(local whichkey {})

(whichkey.packages
  {:which-key {:"folke/which-key.nvim"
                :config (fn []
                          (local wk (require :which-key))
                          (wk.setup {:window {:margin {1 0 1 0}
                                             :padding {1 1 1 1}}
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
                                                          :spelling false}}}))}})

(whichkey.configs {})
(whichkey.settings {})
(whichkey.autocmds [])
(whichkey.cmds [])
(whichkey.binds [])

{: packages whichkey.packages
 : configs whichkey.configs
 : settings whichkey.settings
 : autocmds whichkey.autocmds
 : cmds whichkey.cmds
 : binds whichkey.binds}
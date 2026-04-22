;; gentlewind.modules.features.jj
;; Jujutsu (jj) VCS 集成 — 基于 NicolasGB/jj.nvim
;;
;; JJ 全局配置已写入 ~/.config/jj/config.toml（gruvbox dark 风格）
;; 所有 jj 仓库自动生效，无需逐仓库注入

(local M {})

(set M.packages
  {:jj-nvim {:repo "NicolasGB/jj.nvim"
             :version "*"
             :dependencies ["folke/snacks.nvim"]
             :cmd ["J" "Jdiff" "Jvdiff" "Jhdiff"]
             :config (fn []
                       ((. (require :jj) :setup)
                        {:diff {:backend "native"}
                         :editor {:auto_insert false}
                         :terminal {:window {:type "floating"
                                             :floating_width 0.99
                                             :floating_height 0.95}}
                         :cmd {:describe {:editor {:type "buffer"}}
                              :log {:close_on_edit false}}}))}})

(set M.binds
  {:<leader>j {:name "+jujutsu"
               :j {:cmd (fn []
                           (let [packed [(pcall require :gentlewind.modules.config.dev_tools)]
                                 ok (. packed 1)
                                 dev-tools (. packed 2)]
                             (when ok
                               ((. dev-tools :activate_jj_hydra)))))
                   :desc "JJ: Hydra"}}})

(set M.autocmds [])
(set M.cmds [])
(set M.configs {})
(set M.settings {})

{:packages M.packages
 :configs M.configs
 :settings M.settings
 :autocmds M.autocmds
 :cmds M.cmds
 :binds M.binds}

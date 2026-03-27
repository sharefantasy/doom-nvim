;; user.modules.config.editor
(local M {})

;; 编辑器增强插件配置
(fn M.setup []
  ;; 窗口焦点管理
  (doom.use_package
    {"nvim-focus/focus.nvim"
     :config (fn []
               ((require :focus).setup
                 {:enable true
                  :commands true
                  :autoresize {:enable false
                               :width 0
                               :height 0
                               :minwidth 40
                               :minheight 0
                               :height_quickfix 10}
                  :split {:bufnew false
                          :tmux false}
                  :ui {:number false
                       :relativenumber false
                       :hybridnumber false
                       :absolutenumber_unfocussed false
                       :cursorline true
                       :cursorcolumn false
                       :colorcolumn {:enable false
                                     :list "+1"}
                       :signcolumn true
                       :winhighlight true}}))})

  ;; 快速跳转
  (doom.use_package
    {"folke/flash.nvim"
     :event "VeryLazy"
     :opts {}
     :keys
     [["s" (fn [] ((require :flash).jump)) :mode ["n" "o" "x"] :desc "跳转"]
      ["r" (fn [] ((require :flash).remote)) :mode "o" :desc "远跳"]
      ["<c-s>" (fn [] ((require :flash).toggle)) :mode ["c"] :desc "开关"]]})

  ;; 重复操作增强
  (doom.use_package "tpope/vim-repeat")

  ;; 包围操作
  (doom.use_package
    {"ur4ltz/surround.nvim"
     :config (fn []
               ((require :surround).setup {:mappings_style "sandwich"}))})

  ;; 文本对象增强
  (doom.use_package
    {"chrisgrieser/nvim-various-textobjs"
     :lazy false
     :opts {:keymaps {:useDefaults true}}})

  ;; 书签管理
  (doom.use_package
    {"ThePrimeagen/harpoon"
     :dependencies ["nvim-lua/plenary.nvim"]})

  ;; 代码格式化
  (doom.use_package
    {"stevearc/conform.nvim"
     :opts {}
     :config (fn []
               ((require :conform).setup
                 {:formatters_by_ft {:go ["goimports" "gofmt"]
                                     :lua ["stylua"]
                                     :python ["ruff"]
                                     :javascript ["prettierd"]
                                     :typescript ["prettierd"]
                                     :json ["prettierd"]
                                     :yaml ["prettierd"]
                                     :html ["prettierd"]
                                     :css ["prettierd"]
                                     :markdown ["prettierd"]}
                  :format_on_save {:timeout_ms 500
                                   :lsp_fallback true}}))}))

M)

M

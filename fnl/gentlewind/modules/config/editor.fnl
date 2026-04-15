;; user.modules.config.editor
(local M {})

;; 编辑器增强插件配置
(fn M.setup []
  ;; 窗口焦点管理
  (gentlewind.use_package
    {:repo "nvim-focus/focus.nvim"
     :config (fn []
               ((. (require :focus) :setup)
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
  (gentlewind.use_package
    {:repo "folke/flash.nvim"
     :event "VeryLazy"
     :opts {}
     :keys
     [["gs" (fn [] ((. (require :flash) :jump))) :mode ["n" "o" "x"] :desc "跳转"]]})

  ;; 重复操作增强
  (gentlewind.use_package "tpope/vim-repeat")

  ;; Markdown 预览
  (gentlewind.use_package
    {:repo "iamcco/markdown-preview.nvim"
     :ft ["markdown"]
     :cmd ["MarkdownPreview" "MarkdownPreviewStop" "MarkdownPreviewToggle"]})

  ;; 包围操作
  (gentlewind.use_package
    {:repo "ur4ltz/surround.nvim"
     :config (fn []
              ((. (require :surround) :setup)
                {:mappings_style "sandwich"
                 ;; 关闭 insert-mode 的 <C-s><char> / <C-s><char><space> / <C-s><char><C-s> 这组映射
                 ;; 可消除 which-key 的大量 overlap warning
                 :map_insert_mode false}))})

  ;; 文本对象增强
  (gentlewind.use_package
    {:repo "chrisgrieser/nvim-various-textobjs"
     :lazy false
     :opts {:keymaps {:useDefaults true}}})

  ;; 代码大纲（Symbols/Outline）
  (gentlewind.use_package
    {:repo "stevearc/aerial.nvim"
     :cmd ["AerialToggle" "AerialOpen" "AerialClose" "AerialNavToggle"]
     :dependencies ["nvim-tree/nvim-web-devicons"]
     :config (fn []
               (pcall (fn []
                        (local aerial (require :aerial))
                        ((. aerial :setup)
                         {:backends ["lsp" "treesitter"]
                          :layout {:min_width 30}
                          :attach_mode "global"}))))})

  ;; 书签管理
  (gentlewind.use_package
    {:repo "ThePrimeagen/harpoon"
     :dependencies ["nvim-lua/plenary.nvim"]})

  ;; 代码格式化
  (gentlewind.use_package
    {:repo "stevearc/conform.nvim"
     :opts {}
     :config (fn []
              (let [mason-bin (.. (vim.fn.stdpath :data) "/mason/bin")
                    bin (fn [name] (.. mason-bin "/" name))]
                ((. (require :conform) :setup)
                  {:formatters_by_ft {:go ["goimports" "gofmt"]
                                      :lua ["stylua"]
                                      :python ["ruff_format"]
                                      :javascript ["prettierd"]
                                      :typescript ["prettierd"]
                                      :json ["prettierd"]
                                      :yaml ["prettierd"]
                                      :html ["prettierd"]
                                      :css ["prettierd"]
                                      :markdown ["prettierd"]}
                   ;; align external tool paths: prefer Mason-installed binaries
                   :formatters {:stylua {:command (bin "stylua")}
                                :goimports {:command (bin "goimports")}
                                :prettierd {:command (bin "prettierd")}
                                :ruff_format {:command (bin "ruff")}}
                   ;; headless 下关闭 format_on_save，避免退出时 conform 的 VimLeavePre hack 干扰 Mason 安装。
                   :format_on_save (if (> (# (vim.api.nvim_list_uis)) 0)
                                      {:timeout_ms 500
                                       :lsp_fallback false}
                                      nil)})))})

  ;; UI: noice.nvim + nvim-notify + dressing.nvim
  ;; - noice: 更好的 cmdline / messages / LSP 弹窗
  ;; - notify: 统一 vim.notify
  ;; - dressing: 统一 vim.ui.select/input
  (gentlewind.use_package
    {:repo "rcarriga/nvim-notify"
     :event "VeryLazy"
     :opts {:stages "fade_in_slide_out"
            :timeout 2500
            :render "wrapped-compact"}
     :config (fn []
               (pcall
                 (fn []
                   (local notify (require :notify))
                   (set vim.notify notify))))})

  (gentlewind.use_package
    {:repo "stevearc/dressing.nvim"
     :event "VeryLazy"
     :opts {:input {:insert_only false}
            :select {:backend ["telescope" "builtin"]}}})

  (gentlewind.use_package
    {:repo "folke/noice.nvim"
     :event "VeryLazy"
     :dependencies ["MunifTanjim/nui.nvim" "rcarriga/nvim-notify"]
     :opts {:lsp {:override {"vim.lsp.util.convert_input_to_markdown_lines" true
                             "vim.lsp.util.stylize_markdown" true
                             "cmp.entry.get_documentation" true}}
            :presets {:bottom_search true
                      :command_palette true
                      :long_message_to_split true
                      :inc_rename false
                      :lsp_doc_border true}}})

  )

M

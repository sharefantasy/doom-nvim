;; user.modules.config.dev_tools
(local M {})

;; 开发工具插件配置
(fn M.setup []
  ;; tmux.nvim - tmux集成
  (gentlewind.use_package
    {:repo "aserowy/tmux.nvim"
     :event "VeryLazy"
     :config (fn []
               ((. (require :tmux) :setup)
                 {:copy_sync {:enable true
                              :sync_clipboard false
                              :sync_registers true}
                  :resize {:enable_default_keybindings false}}))})

  ;; refactoring.nvim - 代码重构工具
  (gentlewind.use_package
    {:repo "ThePrimeagen/refactoring.nvim"
     :dependencies ["nvim-lua/plenary.nvim" "nvim-treesitter/nvim-treesitter"]
     :cmd ["Refactor"]
     :config (fn []
               ((. (require :refactoring) :setup)
                 {:prompt_func_return_type {:go true :python true :lua true}
                  :prompt_func_param_type {:go true :python true :lua true}
                  :printf_statements {:go true :python true :lua true}
                  :print_var_statements {:go true :python true :lua true}}))})

  ;; harpoon - 文件标记工具
  (gentlewind.use_package
    {:repo "ThePrimeagen/harpoon"
     :dependencies ["nvim-lua/plenary.nvim"]
     :event "VeryLazy"})

  ;; nvim-tree-remote.nvim - 远程文件管理
  (gentlewind.use_package {:repo "kiyoon/nvim-tree-remote.nvim" :event "VeryLazy"})

  ;; urlview.nvim - URL查看器
  (gentlewind.use_package {:repo "axieax/urlview.nvim" :cmd ["UrlView"]})

  ;; godbolt.nvim - 在线编译器
  (gentlewind.use_package
    {:repo "p00f/godbolt.nvim"
     :cmd ["Godbolt" "GodboltCompiler"]
     :config (fn []
               ((. (require :godbolt) :setup)
                 {:languages {:cpp {:compiler "g122" :options {}}
                              :c {:compiler "cg122" :options {}}
                              :rust {:compiler "r1650" :options {}}}
                  :quickfix {:enable false
                             :auto_open false}
                  :url "https://godbolt.org"}))})

  ;; messages.nvim - 消息管理
  (gentlewind.use_package
    {:repo "AckslD/messages.nvim"
     :cmd ["Messages"]
     :config (fn [] ((. (require :messages) :setup)))})

  ;; nvim-projector - 项目管理
  (gentlewind.use_package
    {:repo "kndndrj/nvim-projector"
     :dependencies ["MunifTanjim/nui.nvim"
                    "kndndrj/projector-neotest"
                    "nvim-neotest/neotest"
                    "kndndrj/projector-dbee"]
     :cmd ["Projector"]
     :config (fn []
               (local projector_dbee (require :projector_dbee))
               ((. (require :projector) :setup)
                 {:outputs [(:new projector_dbee.OutputBuilder)]}))})

  ;; nvim-dap-virtual-text - DAP虚拟文本
  (gentlewind.use_package
    {:repo "theHamsta/nvim-dap-virtual-text"
     :dependencies ["mfussenegger/nvim-dap" "nvim-treesitter/nvim-treesitter"]
     :event "VeryLazy"
     :config (fn []
               ((. (require :nvim-dap-virtual-text) :setup)
                 {:enabled true
                  :enabled_commands true
                  :highlight_changed_variables true
                  :highlight_new_as_changed false
                  :show_stop_reason true
                  :commented false
                  :only_first_definition true
                  :all_references false
                  :clear_on_continue false
                  :display_callback (fn [variable buf stackframe node options]
                                      (if (= "inline" (. options :virt_text_pos))
                                        (.. " = " (string.gsub variable.value "%s+" " "))
                                        (.. variable.name " = " (string.gsub variable.value "%s+" " "))))
                  :virt_text_pos (if (= 1 (vim.fn.has "nvim-0.10")) "inline" "eol")
                  :all_frames false
                  :virt_lines false
                  :virt_text_win_col nil}))})

  ;; spectre.nvim - 搜索替换工具
  (gentlewind.use_package
    {:repo "nvim-pack/nvim-spectre"
     :cmd ["Spectre"]
     :config (fn [] ((. (require :spectre) :setup)))})

  ;; hurl.nvim - HTTP客户端
  (gentlewind.use_package
    {:repo "jellydn/hurl.nvim"
     :dependencies ["MunifTanjim/nui.nvim" "nvim-lua/plenary.nvim" "nvim-treesitter/nvim-treesitter"]
     :ft ["hurl" "http"]
     :opts {:debug false
            :show_notification true
            :mode "split"
            :formatters {:json ["jq"]
                         :html ["prettier" "--parser" "html"]
                         :xml ["tidy" "-xml" "-i" "-q"]}
            :mappings {:close "q"
                       :next_panel "<C-n>"
                       :prev_panel "<C-p>"}}
     :keys [["<leader>te" "<cmd>HurlRunnerToEntry<CR>" :desc "跑请求"]
            ["<leader>tm" "<cmd>HurlToggleMode<CR>" :desc "切模式"]
            ["<leader>tv" "<cmd>HurlVerbose<CR>" :desc "详输出"]
            ["<leader>th" ":HurlRunner<CR>" :desc "选区跑" :mode "v"]]})

  ;; web-tools.nvim - Web开发工具
  (gentlewind.use_package
    {:repo "ray-x/web-tools.nvim"
     :dependencies ["/guihua.lua"]
     :cmd ["Npm" "Yarn" "Npx" "Node" "Pnpm" "StopJob"]
     :config (fn []
               ((. (require :web-tools) :setup)
                 {:keymaps {:rename nil
                            :repeat_rename "."}}))})

  ;; navigator.lua - LSP导航
  (gentlewind.use_package
    {:repo "ray-x/navigator.lua"
     :requires [{:repo "ray-x/guihua.lua" :run "cd lua/fzy && make"}
                {:repo "neovim/nvim-lspconfig"}]
     :event "VeryLazy"})

  ;; sad.nvim - 搜索替换
  (gentlewind.use_package
    {:repo "ray-x/sad.nvim"
     :requires [{:repo "ray-x/guihua.lua" :run "cd lua/fzy && make"}]
     :cmd ["Sad"]
     :config (fn [] ((. (require :sad) :setup) {}))}))

M

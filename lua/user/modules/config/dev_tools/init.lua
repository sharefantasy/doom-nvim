local M = {}

-- 开发工具插件配置
M.setup = function()
  -- tmux.nvim - tmux集成
  doom.use_package {
    "aserowy/tmux.nvim",
    event = "VeryLazy",
    config = function()
      require("tmux").setup {
        copy_sync = {
          enable = true,
          sync_clipboard = false,
          sync_registers = true,
        },
        resize = { enable_default_keybindings = false },
      }
    end,
  }

  -- refactoring.nvim - 代码重构工具
  doom.use_package {
    "ThePrimeagen/refactoring.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "nvim-treesitter/nvim-treesitter" },
    cmd = { "Refactor" },
    config = function()
      require("refactoring").setup {
        prompt_func_return_type = { go = true, python = true, lua = true },
        prompt_func_param_type = { go = true, python = true, lua = true },
        printf_statements = { go = true, python = true, lua = true },
        print_var_statements = { go = true, python = true, lua = true },
      }
    end,
  }

  -- harpoon - 文件标记工具
  doom.use_package {
    "ThePrimeagen/harpoon",
    dependencies = { "nvim-lua/plenary.nvim" },
    event = "VeryLazy",
  }

  -- nvim-tree-remote.nvim - 远程文件管理
  doom.use_package { "kiyoon/nvim-tree-remote.nvim", event = "VeryLazy" }

  -- urlview.nvim - URL查看器
  doom.use_package { "axieax/urlview.nvim", cmd = { "UrlView" } }

  -- godbolt.nvim - 在线编译器
  doom.use_package {
    "p00f/godbolt.nvim",
    cmd = { "Godbolt", "GodboltCompiler" },
    config = function()
      require("godbolt").setup {
        languages = {
          cpp = { compiler = "g122", options = {} },
          c = { compiler = "cg122", options = {} },
          rust = { compiler = "r1650", options = {} },
        },
        quickfix = {
          enable = false,
          auto_open = false,
        },
        url = "https://godbolt.org",
      }
    end,
  }

  -- messages.nvim - 消息管理
  doom.use_package {
    "AckslD/messages.nvim",
    cmd = { "Messages" },
    config = 'require("messages").setup()',
  }

  -- nvim-projector - 项目管理
  doom.use_package {
    "kndndrj/nvim-projector",
    dependencies = {
      "MunifTanjim/nui.nvim",
      "kndndrj/projector-neotest",
      "nvim-neotest/neotest",
      "kndndrj/projector-dbee",
    },
    cmd = { "Projector" },
    config = function()
      require("projector").setup {
        outputs = {
          require("projector_dbee").OutputBuilder:new(),
        },
      }
    end,
  }

  -- nvim-dap-virtual-text - DAP虚拟文本
  doom.use_package {
    "theHamsta/nvim-dap-virtual-text",
    dependencies = {
      "mfussenegger/nvim-dap",
      "nvim-treesitter/nvim-treesitter",
    },
    event = "VeryLazy",
    config = function()
      require("nvim-dap-virtual-text").setup {
        enabled = true,
        enabled_commands = true,
        highlight_changed_variables = true,
        highlight_new_as_changed = false,
        show_stop_reason = true,
        commented = false,
        only_first_definition = true,
        all_references = false,
        clear_on_continue = false,
        display_callback = function(variable, buf, stackframe, node, options)
          if options.virt_text_pos == "inline" then
            return " = " .. variable.value:gsub("%s+", " ")
          else
            return variable.name .. " = " .. variable.value:gsub("%s+", " ")
          end
        end,
        virt_text_pos = vim.fn.has "nvim-0.10" == 1 and "inline" or "eol",
        all_frames = false,
        virt_lines = false,
        virt_text_win_col = nil,
      }
    end,
  }

  -- spectre.nvim - 搜索替换工具
  doom.use_package {
    "nvim-pack/nvim-spectre",
    cmd = { "Spectre" },
    config = function()
      require("spectre").setup()
    end,
  }

  -- hurl.nvim - HTTP客户端
  doom.use_package {
    "jellydn/hurl.nvim",
    dependencies = {
      "MunifTanjim/nui.nvim",
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    ft = { "hurl", "http" },
    opts = {
      debug = false,
      show_notification = true,
      mode = "split",
      formatters = {
        json = { "jq" },
        html = {
          "prettier",
          "--parser",
          "html",
        },
        xml = {
          "tidy",
          "-xml",
          "-i",
          "-q",
        },
      },
      mappings = {
        close = "q",
        next_panel = "<C-n>",
        prev_panel = "<C-p>",
      },
    },
    keys = {
      { "<leader>te", "<cmd>HurlRunnerToEntry<CR>", desc = "Run Api request to entry" },
      { "<leader>tm", "<cmd>HurlToggleMode<CR>", desc = "Hurl Toggle Mode" },
      { "<leader>tv", "<cmd>HurlVerbose<CR>", desc = "Run Api in verbose mode" },
      { "<leader>th", ":HurlRunner<CR>", desc = "Hurl Runner", mode = "v" },
    },
  }

  -- web-tools.nvim - Web开发工具
  doom.use_package {
    "ray-x/web-tools.nvim",
    dependencies = { "/guihua.lua" },
    cmd = { "Npm", "Yarn", "Npx", "Node", "Pnpm", "StopJob" },
    config = function()
      require("web-tools").setup {
        keymaps = {
          rename = nil,
          repeat_rename = ".",
        },
      }
    end,
  }

  -- navigator.lua - LSP导航
  doom.use_package {
    "ray-x/navigator.lua",
    requires = {
      { "ray-x/guihua.lua", run = "cd lua/fzy && make" },
      { "neovim/nvim-lspconfig" },
    },
    event = "VeryLazy",
  }

  -- sad.nvim - 搜索替换
  doom.use_package {
    "ray-x/sad.nvim",
    requires = { "ray-x/guihua.lua", run = "cd lua/fzy && make" },
    cmd = { "Sad" },
    config = function()
      require("sad").setup {}
    end,
  }
end

return M

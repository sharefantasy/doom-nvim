local M = {}

-- 编辑器增强插件配置
M.setup = function()
  -- 窗口焦点管理
  gentlewind.use_package {
    "nvim-focus/focus.nvim",
    config = function()
      require("focus").setup {
        enable = true, -- Enable module
        commands = true, -- Create Focus commands
        autoresize = {
          enable = false, -- Enable or disable auto-resizing of splits
          width = 0, -- Force width for the focused window
          height = 0, -- Force height for the focused window
          minwidth = 40, -- Force minimum width for the unfocused window
          minheight = 0, -- Force minimum height for the unfocused window
          height_quickfix = 10, -- Set the height of quickfix panel
        },
        split = {
          bufnew = false, -- Create blank buffer for new split windows
          tmux = false, -- Create tmux splits instead of neovim splits
        },
        ui = {
          number = false, -- Display line numbers in the focussed window only
          relativenumber = false, -- Display relative line numbers in the focussed window only
          hybridnumber = false, -- Display hybrid line numbers in the focussed window only
          absolutenumber_unfocussed = false, -- Preserve absolute numbers in the unfocussed windows

          cursorline = true, -- Display a cursorline in the focussed window only
          cursorcolumn = false, -- Display cursorcolumn in the focussed window only
          colorcolumn = {
            enable = false, -- Display colorcolumn in the foccused window only
            list = "+1", -- Set the comma-saperated list for the colorcolumn
          },
          signcolumn = true, -- Display signcolumn in the focussed window only
          winhighlight = true, -- Auto highlighting for focussed/unfocussed windows
        },
      }
    end,
  }

  -- 快速跳转
  gentlewind.use_package {
    "folke/flash.nvim",
    event = "VeryLazy",
    ---@type Flash.Config
    opts = {},
    -- stylua: ignore
    keys = {
      {
        "s",
        mode = { "n", "o", "x" },
        function() require("flash").jump() end,
        desc = "跳转"
      }, {
      -- "S",
      -- mode = { "n", "o", "x" },
      -- function() require("flash").treesitter() end,
      -- desc = "Flash Treesitter"
    -- }, {
      "r",
      mode = "o",
      function() require("flash").remote() end,
      desc = "远跳"
    }, {
      -- "R",
      -- mode = { "o", "x" },
      -- function() require("flash").treesitter_search() end,
      -- desc = "Treesitter Search"
    -- }, {
      "<c-s>",
      mode = { "c" },
      function() require("flash").toggle() end,
      desc = "开关"
    }
    }
,
  }

  -- 重复操作增强
  gentlewind.use_package "tpope/vim-repeat"

  -- 包围操作
  gentlewind.use_package {
    "ur4ltz/surround.nvim",
    config = function()
      require("surround").setup { mappings_style = "sandwich" }
    end,
  }

  -- 文本对象增强
  gentlewind.use_package {
    "chrisgrieser/nvim-various-textobjs",
    lazy = false,
    opts = {
      keymaps = {
        useDefaults = true,
      },
    },
  }

  -- 书签管理
  gentlewind.use_package {
    "ThePrimeagen/harpoon",
    dependencies = { "nvim-lua/plenary.nvim" },
  }

  -- 代码重构
  -- gentlewind.use_package {
  --   "ThePrimeagen/refactoring.nvim",
  --   dependencies = { "nvim-lua/plenary.nvim", "nvim-treesitter/nvim-treesitter" },
  --   config = function()
  --     require("refactoring").setup {
  --       prompt_func_return_type = { go = true, python = true, lua = true },
  --       prompt_func_param_type = { go = true, python = true, lua = true },
  --       printf_statements = { go = true, python = true, lua = true },
  --       print_var_statements = { go = true, python = true, lua = true },
  --     }
  --   end,
  -- }

  -- 代码重构（简化版）
  -- gentlewind.use_package {
  --   "ThePrimeagen/refactoring.nvim",
  --   dependencies = { "nvim-lua/plenary.nvim", "nvim-treesitter/nvim-treesitter" },
  --   config = function()
  --     require("refactoring").setup()
  --   end,
  -- }

  -- 代码格式化
  gentlewind.use_package {
    "stevearc/conform.nvim",
    opts = {},
    config = function()
      require("conform").setup {
        formatters_by_ft = {
          go = { "goimports", "gofmt" },
          lua = { "stylua" },
          python = { "ruff" },
          javascript = { "prettierd" },
          typescript = { "prettierd" },
          json = { "prettierd" },
          yaml = { "prettierd" },
          html = { "prettierd" },
          css = { "prettierd" },
          markdown = { "prettierd" },
        },
        format_on_save = {
          timeout_ms = 500,
          lsp_fallback = true,
        },
      }
      -- 移除旧的自动命令，使用format_on_save选项
    end,
  }

  -- 注释增强
  -- gentlewind.use_package {
  --   "nvim-orgmode/orgmode",
  --   dependencies = { { "nvim-treesitter/nvim-treesitter", lazy = true } },
  --   event = "VeryLazy",
  --   config = function()
  --     -- Setup treesitter
  --     require("nvim-treesitter.configs").setup {
  --       highlight = {
  --         enable = true,
  --         additional_vim_regex_highlighting = { "org" },
  --       },
  --       -- ensure_installed = { 'org' },
  --     }
  --
  --     -- Setup orgmode
  --     require("orgmode").setup {
  --       org_agenda_files = "~/orgfiles/**/*",
  --       org_default_notes_file = "~/orgfiles/refile.org",
  --     }
  --   end,
  -- }

  -- 代码注释增强
  -- gentlewind.use_package {
  --   "nvim-pack/nvim-spectre",
  --   config = function()
  --     require("spectre").setup()
  --   end,
  -- }

  -- 代码注释增强
  -- gentlewind.use_package {
  --   "code-biscuits/nvim-biscuits",
  --   requires = { "nvim-treesitter/nvim-treesitter", run = ":TSUpdate" },
  -- }

  -- 环境变量管理
  gentlewind.use_package { "ellisonleao/dotenv.nvim" }

  -- 重复命令增强
  gentlewind.use_package "tpope/vim-repeat"
end

return M

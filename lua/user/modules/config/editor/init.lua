local M = {}

-- 编辑器增强插件配置
M.setup = function()
  -- focus.nvim - 窗口焦点管理
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

  -- surround.nvim - 环绕操作增强
  gentlewind.use_package {
    "ur4ltz/surround.nvim",
    config = function()
      require("surround").setup { mappings_style = "sandwich" }
    end,
  }

  -- flash.nvim - 快速跳转
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
      "S",
      mode = { "n", "o", "x" },
      function() require("flash").treesitter() end,
      desc = "树跳"
    }, {
      "r",
      mode = "o",
      function() require("flash").remote() end,
      desc = "远跳"
    }, {
      "R",
      mode = { "o", "x" },
      function() require("flash").treesitter_search() end,
      desc = "树搜"
    }, {
      "<c-s>",
      mode = { "c" },
      function() require("flash").toggle() end,
      desc = "开关"
    }
    }
    ,
  }

  -- vim-repeat - 重复操作增强
  gentlewind.use_package "tpope/vim-repeat"

  -- nvim-various-textobjs - 文本对象增强
  gentlewind.use_package {
    "chrisgrieser/nvim-various-textobjs",
    lazy = false,
    opts = {
      keymaps = {
        useDefaults = true,
      },
    },
  }

  -- hydra.nvim - 键绑定模式
  gentlewind.use_package "anuvyklack/hydra.nvim"
end

return M

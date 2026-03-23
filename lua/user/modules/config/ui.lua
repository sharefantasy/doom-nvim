local M = {}

-- UI 相关插件配置
M.setup = function()
  -- 主题配置
  doom.use_package {
    "ellisonleao/gruvbox.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("gruvbox").setup {
        terminal_colors = true, -- add neovim terminal colors
        undercurl = true,
        underline = true,
        bold = true,
        italic = {
          strings = true,
          emphasis = true,
          comments = true,
          operators = false,
          folds = true,
        },
        strikethrough = true,
        invert_selection = true,
        invert_signs = false,
        invert_tabline = true,
        invert_intend_guides = true,
        inverse = false, -- invert background for search, diffs, statuslines and errors
        contrast = "soft", -- can be "hard", "soft" or empty string
        palette_overrides = {},
        overrides = {},
        dim_inactive = true,
        transparent_mode = true,
      }
    end,
  }

  -- 状态栏配置（使用heirline替代lualine避免E5248错误）
  doom.use_package {
    "rebelot/heirline.nvim",
    event = "VimEnter",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      -- 简单的状态栏配置
      local StatusLine = {
        -- 文件名
        {
          provider = function()
            return vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":t")
          end,
        },
        { provider = '%=' }, -- 分隔符
        -- 行号列号
        {
          provider = " %l:%c ",
        },
      }
      
      require("heirline").setup({
        statusline = StatusLine,
      })
    end,
  }

  -- 文件浏览器
  doom.use_package {
    "stevearc/oil.nvim",
    cmd = { "Oil" },
    ---@module 'oil'
    ---@type oil.SetupOpts
    opts = {},
    -- Optional dependencies
    -- dependencies = { { "echasnovski/mini.icons", opts = {} } },
    dependencies = { "nvim-tree/nvim-web-devicons" }, -- use if prefer nvim-web-devicons
  }

  -- 大纲视图
  doom.use_package {
    "stevearc/aerial.nvim",
    cmd = { "AerialToggle", "AerialOpen", "AerialClose" },
    opts = {},
    -- Optional dependencies
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
  }

  -- 消息通知
  doom.use_package {
    "folke/noice.nvim",
    event = "VeryLazy",
    dependencies = {
      -- if you lazy-load any plugin below, make sure to add proper `module="...` entries
      "MunifTanjim/nui.nvim", -- OPTIONAL:
      --   `nvim-notify` is only needed, if you want to use the notification view.
      --   If not available, we use `mini` as the fallback
      "rcarriga/nvim-notify",
    },
    config = function()
      require("notify").setup {
        background_colour = "#082828",
      }
      require("noice").setup {
        lsp = {
          view = "cmdline_popup",
          -- override markdown rendering so that **cmp** and other plugins use **Treesitter**
          override = {
            ["vim.lsp.util.convert_input_to_markdown_lines"] = false,
            ["vim.lsp.util.stylize_markdown"] = true,
            ["cmp.entry.get_documentation"] = true,
          },
          signature = {
            enabled = false,
            auto_open = {
              enabled = false,
              trigger = true, -- Automatically show signature help when typing a trigger character from the LSP
              luasnip = true, -- Will open signature help when jumping to Luasnip insert nodes
              throttle = 50, -- Debounce lsp signature help request by 50ms
            },
            -- view = nil, -- when nil, use defaults from documentation
            ---@type NoiceViewOptions
            opts = {}, -- merged with defaults from documentation
          },
        },
        cmdline = {
          enabled = true, -- enables the Noice cmdline UI
          view = "cmdline_popup", -- view for rendering the cmdline. Change to `cmdline` to get a classic cmdline at the bottom
          opts = {}, -- global options for the cmdline. See section on views
          ---@type table<string, CmdlineFormat>
          format = {
            -- conceal: (default=true) This will hide the text in the cmdline that matches the pattern.
            -- view: (default is cmdline view)
            -- opts: any options passed to the view
            -- icon_hl_group: optional hl_group for the icon
            -- title: set to anything or empty string to hide
            cmdline = { pattern = "^:", icon = "🧲", lang = "vim" },
            search_down = {
              kind = "search",
              pattern = "^/",
              icon = "🔎⬇️",
              lang = "regex",
            },
            search_up = {
              kind = "search",
              pattern = "^%?",
              icon = "🔎⬆️",
              lang = "regex",
            },
            filter = { pattern = "^:%s*!", icon = "$", lang = "bash" },
            lua = {
              pattern = {
                "^:%s*lua%s+",
                "^:%s*lua%s*=%s*",
                "^:%s*=%s*",
              },
              icon = "",
              lang = "lua",
            },
            help = { pattern = "^:%s*he?l?p?%s+", icon = "📑" },
            input = {}, -- Used by input()
            -- lua = false, -- to disable a format, set to `false`
          },
        },
        messages = {
          -- NOTE: If you enable messages, then the cmdline is enabled automatically.
          -- This is a current Neovim limitation.
          enabled = false, -- enables the Noice messages UI
          view = "notify", -- default view for messages
          view_error = "notify", -- view for errors
          view_warn = "notify", -- view for warnings
          view_history = "split", -- view for :messages
          view_search = "virtualtext", -- view for search count messages. Set to `false` to disable
          throttle = 10,
          redirect = {
            view = "messages",
            filter = { event = "msg_show" },
          },
        },
        throttle = 100 / 3,
      }
    end,
  }

  -- 消息管理
  doom.use_package {
    "AckslD/messages.nvim",
    config = 'require("messages").setup()',
  }

  -- 标题增强
  doom.use_package {
    "lukas-reineke/headlines.nvim",
    dependencies = "nvim-treesitter/nvim-treesitter",
  }
end

return M

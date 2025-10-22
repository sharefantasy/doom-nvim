local M = {}

-- UI界面插件配置
M.setup = function()
  -- noice.nvim - 消息和命令行美化
  doom.use_package {
    "folke/noice.nvim",
    event = "VeryLazy",
    dependencies = {
      "MunifTanjim/nui.nvim",
      "rcarriga/nvim-notify",
    },
    config = function()
      require("notify").setup {
        background_colour = "#082828",
      }
      require("noice").setup {
        lsp = {
          view = "cmdline_popup",
          override = {
            ["vim.lsp.util.convert_input_to_markdown_lines"] = false,
            ["vim.lsp.util.stylize_markdown"] = true,
            ["cmp.entry.get_documentation"] = true,
          },
          signature = {
            enabled = false,
            auto_open = {
              enabled = false,
              trigger = true,
              luasnip = true,
              throttle = 50,
            },
            opts = {},
          },
        },
        cmdline = {
          enabled = true,
          view = "cmdline_popup",
          opts = {},
          format = {
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
            input = {},
          },
        },
        messages = {
          enabled = false,
          view = "notify",
          view_error = "notify",
          view_warn = "notify",
          view_history = "split",
          view_search = "virtualtext",
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

  -- heirline.nvim - 状态栏（替换lualine避免E5248错误）
  doom.use_package {
    "rebelot/heirline.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      local conditions = require("heirline.conditions")
      local utils = require("heirline.utils")
      
      -- 颜色定义
      local colors = {
        bright_bg = utils.get_highlight("Folded").bg,
        bright_fg = utils.get_highlight("Folded").fg,
        red = utils.get_highlight("DiagnosticError").fg,
        dark_red = utils.get_highlight("DiffDelete").bg,
        green = utils.get_highlight("String").fg,
        blue = utils.get_highlight("Function").fg,
        gray = utils.get_highlight("NonText").fg,
        orange = utils.get_highlight("Constant").fg,
        purple = utils.get_highlight("Statement").fg,
        cyan = utils.get_highlight("Special").fg,
        diag_warn = utils.get_highlight("DiagnosticWarn").fg,
        diag_error = utils.get_highlight("DiagnosticError").fg,
        diag_hint = utils.get_highlight("DiagnosticHint").fg,
        diag_info = utils.get_highlight("DiagnosticInfo").fg,
        git_del = utils.get_highlight("DiffDelete").fg,
        git_add = utils.get_highlight("DiffAdd").fg,
        git_change = utils.get_highlight("DiffChange").fg,
      }
      
      -- 状态栏组件
      local ViMode = {
        -- get vim current mode, this information will be required by the provider
        -- and the highlight functions, so we compute it only once per component
        -- and store it as a component attribute
        init = function(self)
          self.mode = vim.fn.mode(1) -- :h mode()
        end,
        -- Now we define some dictionaries to map the output of mode() to the
        -- corresponding string and color. We can put these into `static` to compute
        -- them at initialisation time.
        static = {
          mode_names = { -- change the strings if you like it vvvvverbose!
            n = "N",
            no = "N?",
            nov = "N?",
            noV = "N?",
            ["no\22"] = "N?",
            niI = "Ni",
            niR = "Nr",
            niV = "Nv",
            nt = "Nt",
            v = "V",
            vs = "Vs",
            V = "V_",
            Vs = "Vs",
            ["\22"] = "^V",
            ["\22s"] = "^V",
            s = "S",
            S = "S_",
            ["\19"] = "^S",
            i = "I",
            ic = "Ic",
            ix = "Ix",
            R = "R",
            Rc = "Rc",
            Rx = "Rx",
            Rv = "Rv",
            Rvc = "Rv",
            Rvx = "Rv",
            c = "C",
            cv = "Ex",
            r = "...",
            rm = "M",
            ["r?"] = "?",
            ["!"] = "!",
            t = "T",
          },
          mode_colors = {
            n = colors.red,
            i = colors.green,
            v = colors.cyan,
            V = colors.cyan,
            ["\22"] = colors.cyan,
            c = colors.orange,
            s = colors.purple,
            S = colors.purple,
            ["\19"] = colors.purple,
            R = colors.orange,
            r = colors.orange,
            ["!"] = colors.red,
            t = colors.red,
          }
        },
        -- We can now access the value of mode() that, by now, would have been
        -- computed by `init()` and use it to index our strings dictionary.
        -- note how `static` fields become just regular attributes once the
        -- component is instantiated.
        -- To be extra meticulous, we can also add some vim statusline format syntax to
        -- control the padding and make sure the string is aligned at the center.
        -- In this case we use `%=` to left and right align the rest of the statusline
        -- and `%=` to center the component. Check `:h statusline` to see all the
        -- available syntax.
        --
        -- After the padding, and using the value computed in `init()`, we get the
        -- corresponding string from the dictionary and apply the highlight to the
        -- entire component using the color we computed in init()
        provider = function(self)
          return " %" .. (self.mode_names[self.mode] or self.mode) .. " %"
        end,
        -- Same goes for the highlight. Now the foreground will change according to the current mode.
        hl = function(self)
          local mode = self.mode:sub(1, 1) -- get only the first mode character
          return { fg = self.mode_colors[mode], bold = true, }
        end,
        -- Recompute the highlight in insert mode, as defined in the `init` function.
        update = {
          "ModeChanged",
          pattern = "*:*",
          callback = vim.schedule_wrap(function()
            vim.cmd("redrawstatus")
          end),
        },
      }
      
      -- FileName block
      local FileNameBlock = {
        -- let's first set up some attributes needed by this component and it's children
        init = function(self)
          self.filename = vim.api.nvim_buf_get_name(0)
        end,
      }
      -- Now let's define some children separately and add them later
      
      -- The Git component
      local Git = {
        condition = conditions.is_git_repo,
        
        init = function(self)
          self.status_dict = vim.b.gitsigns_status_dict
          self.has_changes = self.status_dict.added ~= 0 or self.status_dict.removed ~= 0 or self.status_dict.changed ~= 0
        end,
        
        hl = { fg = colors.orange },
        
        -- Added
        {
          provider = function(self) 
            local count = self.status_dict.added or 0
            return count > 0 and (" +" .. count .. " ") or ""
          end,
          hl = { fg = colors.git_add },
        },
        -- Removed
        {
          provider = function(self)
            local count = self.status_dict.removed or 0
            return count > 0 and (" -" .. count .. " ") or ""
          end,
          hl = { fg = colors.git_del },
        },
        -- Changed
        {
          provider = function(self)
            local count = self.status_dict.changed or 0
            return count > 0 and (" ~" .. count .. " ") or ""
          end,
          hl = { fg = colors.git_change },
        },
      }
      
      -- FileName
      local FileName = {
        provider = function(self)
          -- first, trim the pattern relative to the current directory. For other
          -- options, check :h filename-modifers
          local filename = vim.fn.fnamemodify(self.filename, ":.")
          if filename == "" then return "[No Name]" end
          -- now, if the filename would occupy more than 1/4th of the available
          -- space, we trim the file path to its initials
          -- See also :h statusline
          if not conditions.width_percent_below(#filename, 0.25) then
            filename = vim.fn.pathshorten(filename)
          end
          return filename
        end,
        hl = { fg = utils.get_highlight("Directory").fg },
      }
      
      -- FileFlags
      local FileFlags = {
        {
          condition = function() return vim.bo.modified end,
          provider = " ●",
          hl = { fg = colors.green },
        },
        {
          condition = function() return not vim.bo.modifiable or vim.bo.readonly end,
          provider = function()
            if vim.bo.readonly then
              return " " .. "󰌾" -- lock icon
            else
              return " " .. "󰷈" -- crossed circle icon
            end
          end,
          hl = { fg = colors.orange },
        },
      }
      
      -- FileType
      local FileType = {
        provider = function()
          return string.upper(vim.bo.filetype)
        end,
        hl = { fg = utils.get_highlight("Type").fg, bold = true },
      }
      
      -- FileEncoding
      local FileEncoding = {
        provider = function()
          local enc = (vim.bo.fenc ~= '' and vim.bo.fenc) or vim.o.enc -- :h 'enc'
          return enc ~= 'utf-8' and enc:upper()
        end
      }
      
      -- Ruler
      local Ruler = {
        -- %l = current line number
        -- %L = number of lines in the buffer
        -- %c = column number
        -- %P = percentage through file of displayed window
        provider = " %l:%c %P ",
      }
      
      -- LSP Active
      local LSPActive = {
        condition = conditions.lsp_attached,
        update = {'LspAttach', 'LspDetach'},
        
        -- You can keep it simple,
        -- provider = " 󰒋 LSP ",
        -- Or complicate things a bit and get the servers names
        provider  = function()
          local names = {}
          for _, server in pairs(vim.lsp.get_active_clients({ bufnr = 0 })) do
            table.insert(names, server.name)
          end
          return " 󰒋 [" .. table.concat(names, " ") .. "] "
        end,
        hl = { fg = colors.green, bold = true },
      }
      
      -- Diagnostics
      local Diagnostics = {
        
        condition = conditions.has_diagnostics,
        
        static = {
          error_icon = vim.fn.sign_getdefined("DiagnosticSignError")[1].text or "E",
          warn_icon = vim.fn.sign_getdefined("DiagnosticSignWarn")[1].text or "W",
          info_icon = vim.fn.sign_getdefined("DiagnosticSignInfo")[1].text or "I",
          hint_icon = vim.fn.sign_getdefined("DiagnosticSignHint")[1].text or "H",
        },
        
        init = function(self)
          self.errors = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR })
          self.warnings = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.WARN })
          self.hints = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.HINT })
          self.info = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.INFO })
        end,
        
        update = { "DiagnosticChanged", "BufEnter" },
        
        {
          provider = function(self)
            return self.errors > 0 and (self.error_icon .. self.errors .. " ")
          end,
          hl = { fg = colors.diag_error },
        },
        {
          provider = function(self)
            return self.warnings > 0 and (self.warn_icon .. self.warnings .. " ")
          end,
          hl = { fg = colors.diag_warn },
        },
        {
          provider = function(self)
            return self.info > 0 and (self.info_icon .. self.info .. " ")
          end,
          hl = { fg = colors.diag_info },
        },
        {
          provider = function(self)
            return self.hints > 0 and (self.hint_icon .. self.hints)
          end,
          hl = { fg = colors.diag_hint },
        },
      }
      
      -- The final statusline
      -- Now we just have to assemble the components in the correct order.
      --
      -- The ViMode component is inserted twice, the second one will be used when
      -- the buffer is modified.
      local StatusLine = {
        ViMode,
        Git,
        FileNameBlock,
        FileType,
        FileEncoding,
        Diagnostics,
        { provider = '%=' }, -- The spacer
        LSPActive,
        Ruler,
      }
      
      -- And set heirline up
      require("heirline").setup({
        statusline = StatusLine,
        opts = {
          -- if the callback returns true, the winbar will be disabled for that window
          -- the defaults focus more on what I would consider "global" statusline
          -- components instead of buffer local ones.
          disable_winbar_cb = function(args)
            return vim.tbl_contains({ "NvimTree", "neo-tree", "dashboard", "Trouble", "alpha" },
              vim.bo[args.buf].filetype)
          end,
        },
      })
    end,
  }

  -- heirline.nvim - 状态栏（暂时禁用避免E5248错误）
  -- doom.use_package {
  --   "rebelot/heirline.nvim",
  --   dependencies = { "nvim-tree/nvim-web-devicons" },
  --   config = function()
  --     -- 简单的状态栏配置
  --     local StatusLine = {
  --       -- 文件名
  --       {
  --         provider = function()
  --           return vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":t")
  --         end,
  --       },
  --       { provider = '%=' }, -- 分隔符
  --       -- 行号列号
  --       {
  --         provider = " %l:%c ",
  --       },
  --     }
  --     
  --     require("heirline").setup({
  --       statusline = StatusLine,
  --     })
  --   end,
  -- }

  -- gruvbox.nvim - 主题
  doom.use_package {
    "ellisonleao/gruvbox.nvim",
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
      vim.cmd [[colorscheme gruvbox]]
    end,
  }

  -- barbecue.nvim - 面包屑导航
  -- doom.use_package {
  --   "utilyre/barbecue.nvim",
  --   name = "barbecue",
  --   version = "*",
  --   dependencies = {
  --     "SmiteshP/nvim-navic",
  --     "nvim-tree/nvim-web-devicons",
  --   },
  --   opts = {
  --     -- configurations go here
  --   },
  -- }

  -- oil.nvim - 文件管理器
  doom.use_package {
    "stevearc/oil.nvim",
    ---@module 'oil'
    ---@type oil.SetupOpts
    opts = {},
    dependencies = { "nvim-tree/nvim-web-devicons" },
  }

  -- aerial.nvim - 代码大纲
  -- doom.use_package {
  --   "stevearc/aerial.nvim",
  --   opts = {},
  --   dependencies = {
  --     "nvim-treesitter/nvim-treesitter",
  --     "nvim-tree/nvim-web-devicons",
  --   },
  -- }

  -- headlines.nvim - 标题高亮
  -- doom.use_package {
  --   "lukas-reineke/headlines.nvim",
  --   dependencies = "nvim-treesitter/nvim-treesitter",
  -- }

  -- nvim-biscuits - 代码注释
  -- doom.use_package {
  --   "code-biscuits/nvim-biscuits",
  --   requires = { "nvim-treesitter/nvim-treesitter", run = ":TSUpdate" },
  -- }
end

return M
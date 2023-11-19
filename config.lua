vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
--
-- This file conttdfafafsions for Doom nvim.
-- Just override stuff in the `doom` global table (it's injected into scope
-- automatically).

-- ADDING A PACKAGE
--
doom.use_package {
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

doom.use_package "anuvyklack/hydra.nvim"
doom.use_package {
  "folke/noice.nvim",
  event = "VeryLazy",
  dependencies = {
    -- if you lazy-load any plugin below, make sure to add proper `module="..."` entries
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

doom.use_package {
  "ur4ltz/surround.nvim",
  config = function()
    require("surround").setup { mappings_style = "sandwich" }
  end,
}

doom.use_package "axieax/urlview.nvim"

doom.use_package "kiyoon/nvim-tree-remote.nvim"
doom.use_package {
  "aserowy/tmux.nvim",
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

doom.use_package {
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
      desc = "Flash"
    }, {
    "S",
    mode = { "n", "o", "x" },
    function() require("flash").treesitter() end,
    desc = "Flash Treesitter"
  }, {
    "r",
    mode = "o",
    function() require("flash").remote() end,
    desc = "Remote Flash"
  }, {
    "R",
    mode = { "o", "x" },
    function() require("flash").treesitter_search() end,
    desc = "Treesitter Search"
  }, {
    "<c-s>",
    mode = { "c" },
    function() require("flash").toggle() end,
    desc = "Toggle Flash Search"
  }
  }
,
}

doom.use_package {
  "ThePrimeagen/refactoring.nvim",
  dependencies = { "nvim-lua/plenary.nvim", "nvim-treesitter/nvim-treesitter" },
  config = function()
    require("refactoring").setup {
      prompt_func_return_type = { go = true, python = true, lua = true },
      prompt_func_param_type = { go = true, python = true, lua = true },
      printf_statements = { go = true, python = true, lua = true },
      print_var_statements = { go = true, python = true, lua = true },
    }
  end,
}

doom.use_package {
  "ThePrimeagen/harpoon",
  dependencies = { "nvim-lua/plenary.nvim" },
}

doom.use_package {
  "nvim-lualine/lualine.nvim",
  requires = { "nvim-tree/nvim-web-devicons", opt = true },
  config = function()
    require("lualine").setup {
      options = {
        icons_enabled = true,
        theme = "auto",
        component_separators = { left = "", right = "" },
        section_separators = { left = "", right = "" },
        ignore_focus = {},
        always_divide_middle = true,
        globalstatus = false,
        refresh = { statusline = 1000, tabline = 1000, winbar = 1000 },
      },
      sections = {
        lualine_a = { "mode" },
        lualine_b = { "branch", "diff", "diagnostics" },
        lualine_c = { "filename" },
        lualine_x = { "encoding", "fileformat", "filetype" },
        lualine_y = { "progress" },
        lualine_z = { "location" },
      },
      inactive_sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = { "filename" },
        lualine_x = { "location" },
        lualine_y = {},
        lualine_z = {},
      },
      tabline = {},
      winbar = {},
      inactive_winbar = {},
      extensions = {},
    }
  end,
}

doom.use_package {
  "julienvincent/nvim-paredit",
  config = function()
    require("nvim-paredit").setup()
  end,
  ft = { "scm", "fnl", "elisp" },
}

-- mandatory
doom.use_package { "junegunn/fzf", build = ":call fzf#install()" }
doom.use_package {
  "linrongbin16/fzfx.nvim",
  dependencies = { "junegunn/fzf" },
  config = function()
    require("fzfx").setup()
  end,
}

-- doom.use_package { "kevinhwang91/nvim-bqf", ft = "qf" }

doom.use_package {
  "nvim-orgmode/orgmode",
  dependencies = { { "nvim-treesitter/nvim-treesitter", lazy = true } },
  event = "VeryLazy",
  config = function()
    -- Load treesitter grammar for org
    require("orgmode").setup_ts_grammar()

    -- Setup treesitter
    require("nvim-treesitter.configs").setup {
      highlight = {
        enable = true,
        additional_vim_regex_highlighting = { "org" },
      },
      -- ensure_installed = { 'org' },
    }

    -- Setup orgmode
    require("orgmode").setup {
      org_agenda_files = "~/orgfiles/**/*",
      org_default_notes_file = "~/orgfiles/refile.org",
    }
  end,
}
doom.use_package {
  "lukas-reineke/headlines.nvim",
  dependencies = "nvim-treesitter/nvim-treesitter",
}
doom.use_package {
  "stevearc/conform.nvim",
  opts = {},
  config = function()
    require("conform").setup {
      formatters_by_ft = {
        go = { "goimport", "govet", "gofmt" },
        lua = { "stylua" },
        -- Conform will run multiple formatters sequentially
        python = { "ruff" },
        -- Use a sub-list to run only the first available formatter
        javascript = { { "prettierd", "prettier" } },
      },
    }
    vim.api.nvim_create_autocmd("BufWritePre", {
      pattern = "*",
      callback = function(args)
        require("conform").format { bufnr = args.buf }
      end,
    })
  end,
}

doom.use_package {
  "code-biscuits/nvim-biscuits",
  requires = { "nvim-treesitter/nvim-treesitter", run = ":TSUpdate" },
}

doom.use_package {
  "rgroli/other.nvim",
  config = function()
    require("other-nvim").setup {
      mappings = {
        -- builtin mappings
        "livewire",
        "angular",
        "laravel",
        "rails",
        "golang",
        -- custom mapping
        {
          pattern = "/path/to/file/src/app/(.*)/.*.ext$",
          target = "/path/to/file/src/view/%1/",
          transformer = "lowercase",
        },
      },
      transformers = {
        -- defining a custom transformer
        lowercase = function(inputString)
          return inputString:lower()
        end,
      },
      style = {
        -- How the plugin paints its window borders
        -- Allowed values are none, single, double, rounded, solid and shadow
        border = "solid",

        -- Column seperator for the window
        seperator = "|",

        -- width of the window in percent. e.g. 0.5 is 50%, 1.0 is 100%
        width = 0.7,

        -- min height in rows.
        -- when more columns are needed this value is extended automatically
        minHeight = 2,
      },
    }
  end,
}

-- doom.use_package({
--     "chrisgrieser/nvim-various-textobjs",
--     lazy = false,
--     opts = {useDefaultKeymaps = true}
-- })

doom.use_package {
  "tomiis4/Hypersonic.nvim",
  event = "CmdlineEnter",
  cmd = "Hypersonic",
  config = function()
    require("hypersonic").setup {
      -- config
    }
  end,
}
doom.use_package {
  "VidocqH/lsp-lens.nvim",
  config = function()
    local SymbolKind = vim.lsp.protocol.SymbolKind
    require("lsp-lens").setup {
      enable = true,
      include_declaration = false, -- Reference include declaration
      sections = { -- Enable / Disable specific request, formatter example looks 'Format Requests'
        definition = false,
        references = true,
        implements = true,
        git_authors = true,
      },
      ignore_filetype = { "prisma" },
      -- Target Symbol Kinds to show lens information
      target_symbol_kinds = {
        SymbolKind.Function,
        SymbolKind.Method,
        SymbolKind.Interface,
      },
      -- Symbol Kinds that may have target symbol kinds as children
      wrapper_symbol_kinds = { SymbolKind.Class, SymbolKind.Struct },
    }
  end,
}

doom.use_package {
  "ThePrimeagen/refactoring.nvim",
  dependencies = { "nvim-lua/plenary.nvim", "nvim-treesitter/nvim-treesitter" },
  config = function()
    require("refactoring").setup()
  end,
}

doom.use_package { "gpanders/nvim-parinfer", ft = { "scm", "elisp", "fennel" } }

doom.use_package {
  "ray-x/web-tools.nvim",
  cmd = "HurlRun",
  dependencies = { "/ray-x/guihua.lua" },
  config = function()
    require("web-tools").setup {
      keymaps = {
        rename = nil, -- by default use same setup of lspconfig
        repeat_rename = ".", -- . to repeat
      },
      hurl = { -- hurl default
        show_headers = true, -- do not show http headers
        floating = true, -- use floating windows (need guihua.lua)
        formatters = { -- format the result by filetype
          json = { "jq" },
          html = { "prettier", "--parser", "html" },
        },
      },
    }
  end,
}

doom.use_package {
  "ray-x/navigator.lua",
  requires = {
    { "ray-x/guihua.lua", run = "cd lua/fzy && make" },
    { "neovim/nvim-lspconfig" },
  },
}
doom.use_package {
  "ray-x/sad.nvim",
  requires = { "ray-x/guihua.lua", run = "cd lua/fzy && make" },
  config = function()
    require("sad").setup {}
  end,
}

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

doom.use_package {
  "p00f/godbolt.nvim",
  config = function()
    require("godbolt").setup {
      languages = {
        cpp = { compiler = "g122", options = {} },
        c = { compiler = "cg122", options = {} },
        rust = { compiler = "r1650", options = {} },
        -- any_additional_filetype = { compiler = ..., options = ... },
      },
      quickfix = {
        enable = false, -- whether to populate the quickfix list in case of errors
        auto_open = false, -- whether to open the quickfix list in case of errors
      },
      url = "https://godbolt.org", -- can be changed to a different godbolt instance
    }
  end,
}

doom.indent = 2
doom.core.treesitter.settings.show_compiler_warning_message = false
doom.core.reloader.settings.reload_on_save = true
vim.opt.colorcolumn = "120"

doom.colorscheme = "gruvbox"
doom.freeze_dependencies = false

-- vim: sw=2 sts=2 ts=2 expandtab

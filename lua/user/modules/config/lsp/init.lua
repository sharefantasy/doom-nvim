local M = {}

-- LSP增强插件配置
M.setup = function()
  -- nvim-cmp - 代码补全
  doom.use_package {
    "hrsh7th/nvim-cmp",
    dependencies = {
      {
        "MattiasMTS/cmp-dbee",
        dependencies = {
          { "kndndrj/nvim-dbee" },
        },
        ft = "sql",
        opts = {},
      },
    },
    config = function()
      local cmp = require("cmp")
      cmp.setup {
        sources = cmp.config.sources({
          { name = "codeium" },
          { name = "nvim_lsp" },
          { name = "cmp-dbee" },
          { name = "buffer" },
          { name = "path" },
          { name = "luasnip" },
        }),
        mapping = cmp.mapping.preset.insert({
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"] = cmp.mapping.abort(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            else
              fallback()
            end
          end, { "i", "s" }),
        }),
      }
    end,
  }

  -- codeium.nvim - AI代码补全
  doom.use_package {
    "Exafunction/codeium.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "hrsh7th/nvim-cmp",
    },
    event = "BufEnter",
    config = function()
      require("codeium").setup {
        enable_chat = true,
        enable_cmp_source = true,
      }
    end,
  }

  -- lsp-lens.nvim - LSP透镜
  doom.use_package {
    "VidocqH/lsp-lens.nvim",
    config = function()
      local SymbolKind = vim.lsp.protocol.SymbolKind
      require("lsp-lens").setup {
        enable = true,
        include_declaration = false,
        sections = {
          definition = false,
          references = true,
          implements = true,
          git_authors = true,
        },
        ignore_filetype = { "prisma" },
        target_symbol_kinds = {
          SymbolKind.Function,
          SymbolKind.Method,
          SymbolKind.Interface,
        },
        wrapper_symbol_kinds = { SymbolKind.Class, SymbolKind.Struct },
      }
    end,
  }

  -- Ionide-vim - F#支持 (暂时禁用，有兼容性问题)
  -- doom.use_package "ionide/Ionide-vim"

  -- vim-dadbod - 数据库支持
  doom.use_package "tpope/vim-dadbod"

  -- conform.nvim - 代码格式化
  doom.use_package {
    "stevearc/conform.nvim",
    opts = {},
    config = function()
      require("conform").setup {
        formatters_by_ft = {
          go = { "goimport", "govet", "gofmt" },
          lua = { "stylua" },
          python = { "ruff" },
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

  -- other.nvim - 文件跳转
  doom.use_package {
    "rgroli/other.nvim",
    config = function()
      require("other-nvim").setup {
        mappings = {
          "livewire",
          "angular",
          "laravel",
          "rails",
          "golang",
          {
            pattern = "/path/to/file/src/app/(.*)/.*.ext$",
            target = "/path/to/file/src/view/%1/",
            transformer = "lowercase",
          },
        },
        transformers = {
          lowercase = function(inputString)
            return inputString:lower()
          end,
        },
        style = {
          border = "solid",
          seperator = "|",
          width = 0.7,
          minHeight = 2,
        },
      }
    end,
  }
end

return M
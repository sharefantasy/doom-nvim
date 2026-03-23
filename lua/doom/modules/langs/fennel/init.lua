local fennel = {}

fennel.settings = {
  disable_treesitter = false,
  treesitter_grammars = "fennel",
  disable_lsp = false,
  lsp_name = "fennel_ls",
  disable_formatting = true,
  formatting_package = nil,
  formatting_provider = nil,
  formatting_config = nil,
}

fennel.packages = {
  ["neodev.nvim"] = {
    "folke/neodev.nvim",
    ft = {"fennel", "lua"},
  },
  ["conjure"] = {
    "Olical/conjure",
    ft = {"fennel"},
    dependencies = {"cmp-conjure"},
    config = function()
      require("conjure.main").main()
      require("conjure.mapping")["on-filetype"]()
    end,
  },
  ["cmp-conjure"] = {
    "PaterJason/cmp-conjure",
    ft = {"fennel"},
    dependencies = {"hrsh7th/nvim-cmp"},
    config = function()
      local cmp = require("cmp")
      local config = cmp.get_config()
      table.insert(config.sources, {
        name = "buffer",
        option = {sources = {{name = "conjure"}}},
      })
      cmp.setup(config)
    end,
  },
  ["nfnl"] = {
    "Olical/nfnl",
    ft = {"fennel"},
  },
}

fennel.configs = {}

local langs_utils = require("doom.modules.langs.utils")

fennel.autocmds = {
  {
    "FileType",
    "fennel",
    langs_utils.wrap_language_setup("fennel", function()
      -- 配置neodev以支持Lua符号在Fennel中的访问
      local neodev_avail, neodev = pcall(require, "neodev")
      if neodev_avail then
        neodev.setup({
          library = {
            enabled = true,
            runtime = true,
            types = true,
            plugins = true,
          },
          setup_jsonls = true,
          lspconfig = false,
          pathStrict = true,
          filetypes = {"lua", "fennel"},
          override = function(root_dir, options)
            if string.find(root_dir, "fnl") or string.find(root_dir, "fennel") then
              options.library.enabled = true
              options.library.plugins = true
              options.library.types = true
              options.library.runtime = true
            end
          end,
        })
      end

      if not fennel.settings.disable_lsp then
        langs_utils.use_lsp_mason(fennel.settings.lsp_name)
      end

      if not fennel.settings.disable_treesitter then
        langs_utils.use_tree_sitter(fennel.settings.treesitter_grammars)
        local ts_avail, ts_configs = pcall(require, "nvim-treesitter.configs")
        if ts_avail then
          ts_configs.setup({highlight = {enable = true, disable = {}}})
          vim.schedule(function()
            vim.treesitter.start()
          end)
        end
      end

      doom.use_package { "Olical/conjure", ft = "fennel" }
      doom.use_package { "Olical/nfnl", ft = "fennel" }
    end),
    once = true,
  },
}

fennel.cmds = {}
fennel.binds = {}

return {
  packages = fennel.packages,
  configs = fennel.configs,
  settings = fennel.settings,
  autocmds = fennel.autocmds,
  cmds = fennel.cmds,
  binds = fennel.binds
}

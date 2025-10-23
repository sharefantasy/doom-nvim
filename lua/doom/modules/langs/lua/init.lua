local lua = {}

lua.settings = {
  disable_treesitter = false,
  treesitter_grammars = "lua",
  disable_lsp = false,
  lsp_name = "lua_ls",
  disable_formatting = false,
  formatting_package = "stylua",
  formatting_provider = "builtins.formatting.stylua",
  formatting_config = nil,
  disable_diagnostics = false,
  diagnostics_package = "luacheck",
  diagnostics_provider = "builtins.diagnostics.luacheck",
  diagnostics_config = nil,
  
  neodev = {
    library = {
      enabled = true,
      runtime = true,
      types = true,
      plugins = true
    },
    setup_jsonls = true,
    lspconfig = false,
    pathStrict = true
  }
}

lua.packages = {
  ["lua-dev.nvim"] = {
    "folke/neodev.nvim",
    ft = "lua",
  },
}

lua.configs = {}

local langs_utils = require("doom.modules.langs.utils")

lua.autocmds = {
  {
    "FileType",
    "lua",
    langs_utils.wrap_language_setup("lua", function()
      require("neodev").setup(lua.settings.neodev)
      
      local config = vim.tbl_deep_extend("force", lua.settings.lsp_config or {}, {
        before_init = require("neodev.lsp").before_init
      })
      
      if not lua.settings.disable_lsp then
        langs_utils.use_lsp_mason(lua.settings.lsp_name, {config = config})
      end
      
      if not lua.settings.disable_treesitter then
        langs_utils.use_tree_sitter(lua.settings.treesitter_grammars)
      end
      
      if not lua.settings.disable_formatting then
        langs_utils.use_null_ls(lua.settings.formatting_package,
                               lua.settings.formatting_provider,
                               lua.settings.formatting_config)
      end
      
      if not lua.settings.disable_diagnostics then
        langs_utils.use_null_ls(lua.settings.diagnostics_package,
                               lua.settings.diagnostics_provider,
                               lua.settings.diagnostics_config)
      end
    end),
    once = true
  }
}

lua.cmds = {}
lua.binds = {}

return {
  packages = lua.packages,
  configs = lua.configs,
  settings = lua.settings,
  autocmds = lua.autocmds,
  cmds = lua.cmds,
  binds = lua.binds
}
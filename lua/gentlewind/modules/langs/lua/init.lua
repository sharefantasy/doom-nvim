local lua = {}

lua.settings = {
  --- Disables auto installing the treesitter
  --- @type boolean
  disable_treesitter = false,
  --- Treesitter grammars to install
  --- @type string|string[]
  treesitter_grammars = "lua",

  --- Disables default LSP config
  --- @type boolean
  disable_lsp = false,
  --- Name of the language server
  --- @type string
  lsp_name = "lua_ls",
  --- Custom config to pass to nvim-lspconfig
  --- @type table|nil
  lsp_config = {
    settings = {
      Lua = {
        format = {
          enable = true,
        },
        completion = {
          callSnippet = "Replace",
        },
        workspace = {
          checkThirdParty = false,
          -- 增强workspace配置以支持Fennel中的Lua符号
          library = {
            -- 添加Lua运行时路径
            [vim.fn.expand("$VIMRUNTIME/lua")] = true,
            [vim.fn.expand("$VIMRUNTIME/lua/vim")] = true,
            -- 添加项目中的Fennel路径
            [vim.fn.getcwd() .. "/fnl"] = true,
            [vim.fn.getcwd() .. "/lua"] = true,
          },
          maxPreload = 10000,
          preloadFileSize = 1000,
        },
        telemetry = {
          enable = false,
        },
        -- 增强诊断配置
        diagnostics = {
          enable = true,
          globals = {"vim", "gentlewind", "_gentlewind", "..."},
          disable = {"lowercase-global", "undefined-global", "unused-local", "unused-var"},
        },
      },
    },
  },

  --- Disables null-ls formatting sources
  --- @type boolean
  disable_formatting = false,
  --- Mason.nvim package to auto install the formatter from
  --- @type string
  formatting_package = "stylua",
  --- String to access the null_ls diagnositcs provider
  --- @type string
  formatting_provider = "builtins.formatting.stylua",
  --- Function to configure null-ls formatter
  --- @type function|nil
  formatting_config = nil,

  --- Disables null-ls diagnostic sources
  --- @type boolean
  disable_diagnostics = false,
  --- Mason.nvim package to auto install the diagnostics provider from
  --- @type string
  diagnostics_package = "luacheck",
  --- String to access the null_ls diagnositcs provider
  --- @type string
  diagnostics_provider = "builtins.diagnostics.luacheck",
  --- Function to configure null-ls diagnostics
  --- @type function|nil
  diagnostics_config = nil,

  --- Config for the lua-dev plugin
  neodev = {
    library = {
      enabled = true, -- when not enabled, neodev will not change any settings to the LSP server
      -- these settings will be used for your Neovim config directory
      runtime = true, -- runtime path
      types = true, -- full signature, docs and completion of vim.api, vim.treesitter, vim.lsp and others
      plugins = true, -- installed opt or start plugins in packpath
      -- 添加对Fennel文件的支持
      vim_reg = true, -- 启用vim正则表达式支持
    },
    setup_jsonls = true, -- configures jsonls to provide completion for project specific .luarc.json files
    -- for your Neovim config directory, the config.library settings will be used as is
    -- for plugin directories (root_dirs having a /lua directory), config.library.plugins will be disabled
    -- for any other directory, config.library.enabled will be set to false
    override = function(root_dir, options)
      -- 为Fennel项目启用增强的库支持
      if string.find(root_dir, "fnl") or string.find(root_dir, "fennel") then
        options.library.enabled = true
        options.library.plugins = true
        options.library.types = true
        options.library.runtime = true
      end
    end,
    -- With lspconfig, Neodev will automatically setup your lua-language-server
    -- If you disable this, then you have to set {before_init=require("neodev.lsp").before_init}
    -- in your lsp start options
    -- WARN: Do not change this setting.
    lspconfig = false,
    -- much faster, but needs a recent built of lua-language-server
    -- needs lua-language-server >= 3.6.0
    pathStrict = true
  }
}

lua.packages = {
  ["lua-dev.nvim"] = {
    "folke/neodev.nvim",
    ft = {"lua", "fennel"},
  },
}

lua.configs = {}

local langs_utils = require("gentlewind.modules.langs.utils")

lua.autocmds = {
  {
    "FileType",
    "lua",
    langs_utils.wrap_language_setup("lua", function()
      -- 配置neodev以支持Fennel中的Lua符号访问
      require("neodev").setup({
        library = {
          enabled = true,
          runtime = true,
          types = true,
          plugins = true,
          vim_reg = true,
        },
        setup_jsonls = true,
        lspconfig = false,
        pathStrict = true,
        -- 添加对Fennel文件的支持
        filetypes = {"lua", "fennel"},
        override = function(root_dir, options)
          -- 为Fennel项目启用增强的库支持
          if string.find(root_dir, "fnl") or string.find(root_dir, "fennel") then
            options.library.enabled = true
            options.library.plugins = true
            options.library.types = true
            options.library.runtime = true
          end
        end,
      })
      
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
local go = {}

go.settings = {
  --- Disables auto installing the treesitter
  --- @type boolean
  disable_treesitter = false,
  --- Treesitter grammars to install
  --- @type string|string[]
  treesitter_grammars = "go",

  --- Disables default LSP config
  --- @type boolean
  disable_lsp = false,
  --- Name of the language server
  --- @type string
  lsp_name = "gopls",
  --- Custom config to pass to nvim-lspconfig
  --- @type table|nil
  lsp_config = nil,

  --- Disables null-ls formatting sources
  --- @type boolean
  disable_formatting = false,
  --- Mason.nvim package to auto install the formatter from
  --- @type string
  formatting_package = "gofumpt",
  --- String to access the null_ls diagnositcs provider
  --- @type string
  formatting_provider = "builtins.formatting.gofumpt",
  --- Function to configure null-ls formatter
  --- @type function|nil
  formatting_config = nil,

  --- Disables null-ls diagnostic sources
  --- @type boolean
  disable_diagnostics = false,
  --- Mason.nvim package to auto install the diagnostics provider from
  --- @type string
  diagnostics_package = "golangci-lint",
  --- String to access the null_ls diagnositcs provider
  --- @type string
  diagnostics_provider = "builtins.diagnostics.golangci_lint",
  --- Function to configure null-ls diagnostics
  --- @type function|nil
  diagnostics_config = nil,
}

go.packages = {
  ["go"] = {
    "ray-x/go.nvim",
    dependencies = { -- optional packages
      "ray-x/guihua.lua",
      "neovim/nvim-lspconfig",
      "nvim-treesitter/nvim-treesitter",
    },
    event = { "CmdlineEnter" },
    ft = { "go", "gomod" },
    build = ':lua require("go.install").update_all_sync()', -- if you need to install/update all binaries
  },
  ["go-dap"] = {
    "leoluz/nvim-dap-go",
    cmd = { "DapContinue" },
    event = { "CmdlineEnter" },
    ft = { "go", "gomod" },
  },
}

go.configs = {}
go.configs["go"] = function()
  require("go").setup()
  vim.g.go_addtags_transform = "camelcase"
end

go.configs["go-dap"] = function()
  require("dap-go").setup {
    -- Additional dap configurations can be added.
    -- dap_configurations accepts a list of tables where each entry
    -- represents a dap configuration. For more details do:
    -- :help dap-configuration
    dap_configurations = {
      {
        -- Must be "go" or it will be ignored by the plugin
        type = "go",
        name = "Attach remote",
        mode = "remote",
        request = "attach",
      },
    },
    -- delve configurations
    delve = {
      -- the path to the executable dlv which will be used for debugging.
      -- by default, this is the "dlv" executable on your PATH.
      path = "dlv",
      -- time to wait for delve to initialize the debug session.
      -- default to 20 seconds
      initialize_timeout_sec = 20,
      -- a string that defines the port to start delve debugger.
      -- default to string "${port}" which instructs nvim-dap
      -- to start the process in a random available port
      port = "${port}",
      -- additional args to pass to dlv
      args = {},
      -- the build flags that are passed to delve.
      -- defaults to empty string, but can be used to provide flags
      -- such as "-tags=unit" to make sure the test suite is
      -- compiled during debugging, for example.
      -- passing build flags using args is ineffective, as those are
      -- ignored by delve in dap mode.
      build_flags = "",
    },
  }
end

local langs_utils = require "doom.modules.langs.utils"
go.autocmds = {
  {
    "BufWinEnter",
    "*.go",
    langs_utils.wrap_language_setup("go", function()
      if not go.settings.disable_lsp then
        langs_utils.use_lsp_mason(go.settings.lsp_name, { config = go.settings.lsp_config })
      end

      if not go.settings.disable_treesitter then
        langs_utils.use_tree_sitter(go.settings.treesitter_grammars)
      end

      if not go.settings.disable_formatting then
        langs_utils.use_null_ls(
          go.settings.formatting_package,
          go.settings.formatting_provider,
          go.settings.formatting_config
        )
      end
      if not go.settings.disable_diagnostics then
        langs_utils.use_null_ls(
          go.settings.diagnostics_package,
          go.settings.diagnostics_provider,
          go.settings.diagnostics_config
        )
      end
    end),
    once = true,
  },
}

return go

local sql = {}

sql.settings = {
  --- Disables auto installing the treesitter
  --- @type boolean
  disable_treesitter = false,
  --- Treesitter grammars to install
  --- @type string|string[]
  treesitter_grammars = "sql",

  --- Disables default LSP config
  --- @type boolean
  disable_lsp = false,
  --- Name of the language server
  --- @type string
  lsp_name = "sqlls",
  --- Custom config to pass to nvim-lspconfig
  --- @type table|nil
  lsp_config = nil,

  --- Disables null-ls formatting sources
  --- @type boolean
  disable_formatting = false,
  --- Mason.nvim package to auto install the formatter from
  --- @type string
  formatting_package = "sqlfmt",
  --- String to access the null_ls diagnositcs provider
  --- @type string
  formatting_provider = "builtins.formatting.sqlfmt",
  --- Function to configure null-ls formatter
  --- @type function|nil
  formatting_config = nil,

  --- Disables null-ls diagnostic sources
  --- @type boolean
  disable_diagnostics = true,
  --- Mason.nvim package to auto install the diagnostics provider from
  --- @type string
  diagnostics_package = "sqlfluff",
  --- String to access the null_ls diagnositcs provider
  --- @type string
  diagnostics_provider = "builtins.diagnostics.sqlfluff",
  --- Function to configure null-ls diagnostics
  --- @type function|nil
  diagnostics_config = nil,
}

local langs_utils = require("doom.modules.langs.utils")
sql.autocmds = {
  {
    "FileType",
    "sql",
    langs_utils.wrap_language_setup("sql", function()
      if not sql.settings.disable_lsp then
        langs_utils.use_lsp_mason(sql.settings.lsp_name)
      end

      if not sql.settings.disable_treesitter then
        langs_utils.use_tree_sitter(sql.settings.treesitter_grammars)
      end

      if not sql.settings.disable_formatting then
        langs_utils.use_null_ls(
          sql.settings.formatting_package,
          sql.settings.formatting_provider,
          sql.settings.formatting_config
        )
      end
      if not sql.settings.disable_diagnostics then
        langs_utils.use_null_ls(
          sql.settings.diagnostics_package,
          sql.settings.diagnostics_provider,
          sql.settings.diagnostics_config
        )
      end
    end),
    once = true,
  },
}

return sql

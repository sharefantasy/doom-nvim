local clojure = {}

clojure.settings = {
  --- Disables auto installing the treesitter
  --- @type boolean
  disable_treesitter = false,
  --- Treesitter grammars to install
  --- @type string|string[]
  treesitter_grammars = "clojure",

  --- Disables default LSP config
  --- @type boolean
  disable_lsp = false,
  --- Name of the language server
  --- @type string
  lsp_name = "clojure_lsp",

  --- Disables null-ls formatting sources
  --- @type boolean
  disable_formatting = true,
  --- Mason.nvim package to auto install the formatter from
  --- @type string
  formatting_package = "clojure_format",
  --- String to access the null_ls diagnositcs provider
  --- @type string
  formatting_provider = "builtins.formatting.clojure_format",
  --- Function to configure null-ls formatter
  --- @type function|nil
  formatting_config = nil,
}

local langs_utils = require "doom.modules.langs.utils"
clojure.autocmds = {
  {
    "FileType",
    "clojure",
    langs_utils.wrap_language_setup("clojure", function()
      if not clojure.settings.disable_lsp then
        langs_utils.use_lsp_mason(clojure.settings.lsp_name)
      end

      if not clojure.settings.disable_treesitter then
        langs_utils.use_tree_sitter(clojure.settings.treesitter_grammars)
      end

      if not clojure.settings.disable_formatting then
        langs_utils.use_null_ls(
          clojure.settings.formatting_package,
          clojure.settings.formatting_provider,
          clojure.settings.formatting_config
        )
      end
    end),
    once = true,
  },
}

doom.use_package {
  "Olical/conjure",
  ft = { "clojure", "fennel" }, -- etc
  dependencies = {
    {
      "PaterJason/cmp-conjure",
      config = function()
        local cmp = require "cmp"
        local config = cmp.get_config()
        table.insert(config.sources, {
          name = "buffer",
          option = { sources = { { name = "conjure" } } },
        })
        cmp.setup(config)
      end,
    },
  },
  config = function()
    require("conjure.main").main()
    require("conjure.mapping")["on-filetype"]()
  end,
  init = function()
    -- Set configuration options here
    vim.g["conjure#debug"] = true
  end,
}

return clojure

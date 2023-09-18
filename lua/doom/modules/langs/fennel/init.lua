local fennel = {}

fennel.settings = {
  --- Disables auto installing the treesitter
  --- @type boolean
  disable_treesitter = false,
  --- Treesitter grammars to install
  --- @type string|string[]
  treesitter_grammars = "fennel",

  --- Disables default LSP config
  --- @type boolean
  disable_lsp = false,
  --- Name of the language server
  --- @type string
  lsp_name = "fennel_language_server",

  --- Disables null-ls formatting sources
  --- @type boolean
  disable_formatting = true,
  --- Mason.nvim package to auto install the formatter from
  --- @type string
  formatting_package = "fnlfmt",
  --- String to access the null_ls diagnositcs provider
  --- @type string
  formatting_provider = "builtins.formatting.fnlfmt",
  --- Function to configure null-ls formatter
  --- @type function|nil
  formatting_config = nil,
}

local langs_utils = require("doom.modules.langs.utils")
fennel.autocmds = {
  {
    "FileType",
    "fennel",
    langs_utils.wrap_language_setup("fennel", function()
      if not fennel.settings.disable_lsp then
        langs_utils.use_lsp_mason(fennel.settings.lsp_name)
      end

      if not fennel.settings.disable_treesitter then
        langs_utils.use_tree_sitter(fennel.settings.treesitter_grammars)
      end

      if not fennel.settings.disable_formatting then
        langs_utils.use_null_ls(
          fennel.settings.formatting_package,
          fennel.settings.formatting_provider,
          fennel.settings.formatting_config
        )
      end

      doom.use_package({
          "Olical/conjure",
          ft = { "fennel", "fennel", "python" }, -- etc
          dependencies = {
            {
              "PaterJason/cmp-conjure",
              config = function()
                local cmp = require("cmp")
                local config = cmp.get_config()
                table.insert(config.sources, {
                  name = "buffer",
                  option = {
                    sources = {
                      { name = "conjure" },
                    },
                  },
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
        })
      doom.use_package({ "Olical/nfnl", ft = "fennel" })

    end),
    once = true,
  },
}


return fennel

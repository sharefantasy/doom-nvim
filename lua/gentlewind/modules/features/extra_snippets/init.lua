local extra_snippets = {}

extra_snippets.settings = {}

extra_snippets.packages = {
  ["friendly-snippets"] = { "rafamadriz/friendly-snippets", event = "VeryLazy" },
  ["luasnip_snippets.nvim"] = { "molleweide/LuaSnip-snippets.nvim", event = "VeryLazy" },
}

extra_snippets.requires_modules = { "features.lsp" }
extra_snippets.configs = {}
extra_snippets.configs["friendly-snippets"] = function()
  require("luasnip.loaders.from_vscode").lazy_load()
end

-- extra_snippets.configs["luasnip_snippets.nvim"] = function()
--   local luasnip = require "luasnip"
--   -- be sure to load this first since it overwrites the snippets table.
--   luasnip.snippets = require("luasnip-snippets").load_snippets()
-- end

return extra_snippets

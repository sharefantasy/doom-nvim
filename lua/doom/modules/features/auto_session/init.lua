local auto_session = {}

auto_session.settings = { dir = vim.fn.stdpath "data" .. "/sessions/" }

auto_session.packages = {
  ["persistence.nvim"] = {
    "folke/persistence.nvim",
  },
}

auto_session.configs = {}
auto_session.configs["persistence.nvim"] = function()
  require("persistence").setup(doom.features.auto_session.settings)
end

auto_session.binds = {
  { "<leader>", group = "prefix", {
    { "q", group = "quit", {
        { "r", function()
            require("persistence").load { last = true }
          end, desc = "Restore session" },
        { "l", function()
            require("persistence").load()
          end, desc = "Restore Last Session in current directory" },
      },
    },
  }},
}

return auto_session

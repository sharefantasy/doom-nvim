local auto_session = {}

auto_session.settings = {
  dir = vim.fn.stdpath("data") .. "/sessions/",
}

auto_session.packages = {
  ["persistence.nvim"] = {
    "folke/persistence.nvim",
    commit = "4b8051c01f696d8849a5cb8afa9767be8db16e40",
  },
}

auto_session.configs = {}
auto_session.configs["persistence.nvim"] = function()
  require("persistence").setup(doom.features.auto_session.settings)
end

auto_session.binds = {
  "<leader>",
  name = "+prefix",
  {
    {
      "q",
      name = "+quit",
      {
        {
          "r",
          function()
            require("persistence").load({ last = true })
          end,
          name = "Restore session",
        },
      },
    },
  },
}

return auto_session

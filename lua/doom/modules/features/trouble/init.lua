local trouble = {}

trouble.settings = {}

trouble.packages = {
  ["trouble.nvim"] = {
    "folke/trouble.nvim",
    commit = "40aad004f53ae1d1ba91bcc5c29d59f07c5f01d3",
    cmd = { "Trouble", "TroubleClose", "TroubleRefresh", "TroubleToggle" },
    lazy = false,
  },
}

trouble.configs = {}
trouble.configs["trouble.nvim"] = function()
  require("trouble").setup(doom.features.trouble.settings)
end

trouble.binds = {
  "<leader>",
  name = "+prefix",
  {
    {
      "o",
      name = "+open/close",
      {
        { "T", "<cmd>TroubleToggle<CR>", name = "Trouble" },
      },
    },
    {
      "c",
      name = "+code",
      {
        { "e", "<cmd>TroubleToggle<CR>", name = "Open trouble" },
        {
          "d",
          name = "+diagnostics",
          {
            { "t", "<cmd>TroubleToggle<CR>", name = "Trouble" },
          },
        },
      },
    },
  },
}

return trouble

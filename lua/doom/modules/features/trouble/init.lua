local trouble = {}

trouble.settings = {}

trouble.packages = {
  ["trouble.nvim"] = {
    "folke/trouble.nvim",
    commit = "3f85d8ed30e97ceeddbbcf80224245d347053711",
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

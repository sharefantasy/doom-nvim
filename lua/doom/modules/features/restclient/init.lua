local restclient = {}

restclient.settings = {}

restclient.packages = {
  ["rest.nvim"] = {
    "rest-nvim/rest.nvim",
    cmd = {
      "RestNvim",
      "RestNvimPreview",
      "RestNvimLast",
    },
  },
}

restclient.configs = {}
restclient.configs["rest.nvim"] = function()
  require("rest-nvim").setup(doom.features.restclient.settings)
end

restclient.binds = {
  { "<F7>", "<cmd>RestNvim<CR>", desc = "Open http client" },
  {
    "<leader>",
    group = "+prefix",
    {
      {
        "o",
        group = "+open/close",
        {
          { "h", "<cmd>RestNvim<CR>", desc = "Http" },
        },
      },
    },
  },
}

return restclient

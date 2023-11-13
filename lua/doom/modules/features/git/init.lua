local git = {}

git.settings = {}

git.packages = {
  ["neogit"] = {
    "TimUntersberger/neogit",
    cmd = "Neogit",
    lazy = true,
  },
  ["blame"] = {
    "FabijanZulj/blame.nvim",
    cmd = "ToggleBlame",
    lazy = true,
  },
}

git.configs = {}
git.configs["neogit"] = function()
  require("neogit").setup(doom.features.git.settings)

end

git.binds = {
  "<leader>",
  name = "+prefix",
  {
    {
      "g",
      name = "+git",
      {
        { "g", "<cmd>Neogit<CR>", name = "Open neogit" },
        { "b", "<cmd>ToggleBlame window<CR>", name = "Open GitBlame" }
      },
    },
  },
}

return git

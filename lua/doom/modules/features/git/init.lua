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
  ["diffview"] = {
    "sindrets/diffview.nvim",
    cmd = "DiffviewOpen",
    lazy = true,
  }
}

git.configs = {}
git.configs["neogit"] = function()
  require("neogit").setup({})
end

git.configs["diffview"] = function()
    require("diffview").setup({
      view = {
        default = {
          layout = "diff2_horizontal",
          winbar_info = false,
        },
        merge_tool = {
          layout = "diff3_horizontal",
          disable_diagnostics = true, -- Temporarily disable diagnostics for conflict buffers while in the view.
          winbar_info = true, -- See ':h diffview-config-view.x.winbar_info'
        },
        file_history = {
          -- Config for changed files in file history views.
          layout = "diff2_horizontal",
          winbar_info = false, -- See ':h diffview-config-view.x.winbar_info'
        },
      },
    })
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
        { "b", "<cmd>ToggleBlame window<CR>", name = "Open GitBlame" },
        {"d" ,
          {
            -- {"b", name = "Diff Revision"},
            {"h", "<cmd>DiffviewOpen HEAD<CR>", name = "Diff Head"},
          },
          name = "DiffView"
        }
      },
    },
  },
}


return git

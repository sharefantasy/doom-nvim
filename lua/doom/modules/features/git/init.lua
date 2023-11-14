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
  },
  ["fzf-lua"] = {
    "ibhagwan/fzf-lua",
    -- optional for icon support
    dependencies = { "nvim-tree/nvim-web-devicons" },
  },
}

git.configs = {}
git.configs["neogit"] = function()
  require("neogit").setup({
    kind = "vsplit",
    integrations = {
      -- If enabled, use telescope for menu selection rather than vim.ui.select.
      -- Allows multi-select and some things that vim.ui.select doesn't.
      telescope = true,
      -- Neogit only provides inline diffs. If you want a more traditional way to look at diffs, you can use `diffview`.
      -- The diffview integration enables the diff popup.
      --
      -- Requires you to have `sindrets/diffview.nvim` installed.
      diffview = true,

      -- If enabled, uses fzf-lua for menu selection. If the telescope integration
      -- is also selected then telescope is used instead
      -- Requires you to have `ibhagwan/fzf-lua` installed.
      fzf_lua = true,
    },
  })
end

git.configs["fzf-lua"] = function()
  require("fzf-lua").setup({})
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
        winbar_info = true,         -- See ':h diffview-config-view.x.winbar_info'
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
        { "s", "<cmd>Neogit<CR>",             name = "Open neogit" },
        { "b", "<cmd>ToggleBlame window<CR>", name = "Open GitBlame" },
        {
          "d",
          {
            -- {"b", name = "Diff Revision"},
            { "h", "<cmd>DiffviewOpen HEAD<CR>", name = "Diff Head" },
          },
          name = "DiffView",
        },
      },
    },
  },
}

return git

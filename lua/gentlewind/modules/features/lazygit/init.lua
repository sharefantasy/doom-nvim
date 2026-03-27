local lazygit = {}

lazygit.settings = {}

lazygit.packages = {
  ["lazygit.nvim"] = {
    "kdheepak/lazygit.nvim",
    cmd = { "LazyGit", "LazyGitConfig" },
    lazy = true,
  },
}

lazygit.binds = {
  { "<leader>", group = "prefix", {
    { "o", group = "open/close", {
        { "l", "<cmd>LazyGit<CR>", desc = "Lazygit" } },
    },
    { "g", group = "git", {
        { "o", "<cmd>LazyGit<CR>", desc = "Open lazygit" } },
    },
  }},
}

return lazygit

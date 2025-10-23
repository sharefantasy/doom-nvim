local neogit = {}

neogit.settings = {}

neogit.packages = {
  ["neogit"] = {
    "NeogitOrg/neogit",
    cmd = "Neogit",
    lazy = true,
  },
}

neogit.configs = {}
neogit.configs["neogit"] = function()
    require("neogit").setup(doom.features.neogit.settings)
end

neogit.binds = {
    { "<leader>", group = "prefix", {
        { "o", group = "open/close", { { "g", "<cmd>Neogit<CR>", desc = "Neogit" } } },
        { "g", group = "git", { { "g", "<cmd>Neogit<CR>", desc = "Open neogit" } } }
    }}
}

return neogit

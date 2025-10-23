local trouble = {}

trouble.settings = {}

trouble.packages = {
  ["trouble.nvim"] = {
    "folke/trouble.nvim",
    cmd = { "Trouble", "TroubleClose", "TroubleRefresh", "TroubleToggle" },
    lazy = true,
  },
}

trouble.configs = {}
trouble.configs["trouble.nvim"] = function()
    require("trouble").setup(doom.features.trouble.settings)
end

trouble.binds = {
    { "<leader>", group = "prefix", {
        { "o", group = "open/close", { { "T", "<cmd>TroubleToggle<CR>", desc = "Trouble" } } },
        { "c", group = "code", {
                { "e", "<cmd>TroubleToggle<CR>", desc = "Open trouble" },
                { "d", group = "diagnostics", { { "t", "<cmd>TroubleToggle<CR>", desc = "Trouble" } } }
            }
        }
    }}
}

return trouble

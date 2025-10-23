local suda = {}

suda.settings = {}

suda.packages = {
  ["suda.vim"] = {
    "lambdalisue/suda.vim",
    lazy = true,
    cmd = { "SudaRead", "SudaWrite" },
  },
}

suda.configs = {}

suda.binds = {
    "<leader>",
    group = "+prefix",
    {
        {
            "f",
            group = "+file",
            {
                {"R", "<cmd>SudaRead<CR>", desc = "Read with sudo"},
                {"W", "<cmd>SudaWrite<CR>", desc = "Write with sudo"}
            }
        }
    }
}

return suda

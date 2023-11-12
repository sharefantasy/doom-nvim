local test = {}

test.settings = {}

test.packages = {
  ["test"] = {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "antoinemadec/FixCursorHold.nvim",
      "Issafalcon/neotest-dotnet",
      "nvim-neotest/neotest-go",
      "nvim-neotest/neotest-python",
      "nvim-neotest/neotest-plenary",
      "nvim-neotest/neotest-vim-test",
    },
  },
}

test.configs = {}
test.configs["test"] = function()
  local neotest_ns = vim.api.nvim_create_namespace("neotest")
  vim.diagnostic.config({
    virtual_text = {
      format = function(diagnostic)
        local message =
          diagnostic.message:gsub("\n", " "):gsub("\t", " "):gsub("%s+", " "):gsub("^%s+", "")
        return message
      end,
    },
  }, neotest_ns)
  require("neotest").setup({
    adapters = {
      require("neotest-go"),
      require("neotest-dotnet"),
      require("neotest-python")({
        dap = { justMyCode = false },
      }),
      require("neotest-plenary"),
      require("neotest-vim-test")({
        ignore_file_types = { "python", "vim", "lua" },
      }),
    },
  })
end

test.binds = {
  {
    "<leader>",
    name = "+prefix",
    {
      {
        "x",
        name = "+test",
        {
          {
            "t",
            name = "run current test",
            function()
              require("neotest").run.run()
            end,
          },
          {
            "f",
            name = "run file test",
            function()
              require("neotest").run.run(vim.fn.expand("%"))
            end,
          },
          {
            "d",
            name = "run debug test",
            function()
              require("neotest").run.run({ strategy = "dap" })
            end,
          },
        },
      },
    },
  },
}

return test

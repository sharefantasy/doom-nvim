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
    cmd = "Neotest",
  },
}

test.configs = {}
test.configs["test"] = function()
  local neotest_ns = vim.api.nvim_create_namespace "neotest"
  vim.diagnostic.config({
    virtual_text = {
      format = function(diagnostic)
        local message = diagnostic.message:gsub("\n", " "):gsub("\t", " "):gsub("%s+", " "):gsub("^%s+", "")
        return message
      end,
    },
  }, neotest_ns)
  require("neotest").setup {
    adapters = {
      require "neotest-go",
      require "neotest-dotnet",
      require "neotest-python" { dap = { justMyCode = false } },
      require "neotest-plenary",
      require "neotest-vim-test" { ignore_file_types = { "python", "vim", "lua" } },
    },
  }
end

test.binds = {
  { "<leader>", group = "prefix", {
    { "x", group = "test", {
        { "t", function()
              local neotest = require "neotest"
              neotest.output_panel.open()
              neotest.summary.open()
              neotest.run.run()
            end, desc = "run current test" },
        { "f", function()
              local neotest = require "neotest"
              neotest.output_panel.open()
              neotest.summary.open()
              neotest.run.run(vim.fn.expand "%")
            end, desc = "run file test" },
        { "d", function()
              local neotest = require "neotest"
              neotest.output_panel.open()
              neotest.summary.open()
              neotest.run.run { strategy = "dap" }
            end, desc = "run debug test" },
        { "c", function()
              local neotest = require "neotest"
              neotest.output_panel.close()
              neotest.summary.close()
            end, desc = "close test windows" },
      },
    },
  }},
}

return test

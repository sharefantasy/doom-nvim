local dap = {}

dap.settings = {
  debugger_dir = vim.fn.stdpath("data") .. "/dapinstall/",
  debugger_map = {},
  dapui = {
    icons = {
      expanded = "▾",
      collapsed = "▸",
    },
    mappings = {
      expand = { "<CR>", "<2-LeftMouse>" },
      open = "o",
      remove = "d",
      edit = "e",
      repl = "r",
    },
    layouts = {
      {
        elements = {
          "scopes",
          "breakpoints",
          "stacks",
          "watches",
        },
        size = 40,
        position = "left",
      },
      {
        elements = {
          "repl",
          "console",
        },
        size = 10,
        position = "bottom",
      },
    },
  },
}

dap.packages = {
  ["nvim-dap"] = {
    "mfussenegger/nvim-dap",
  },
  ["nvim-dap-ui"] = {
    "rcarriga/nvim-dap-ui",
    dependencies = {
      "mfussenegger/nvim-dap",
    },
    after = { "nvim-dap" },
  },
  ["osv"] = {
    "jbyuki/one-small-step-for-vimkind",
    dependencies = {
      "mfussenegger/nvim-dap",
    },
    after = { "nvim-dap" },
  },
}

dap.configs = {}
dap.configs["nvim-dap-ui"] = function()
  local dap_package = require("dap")
  local dapui = require("dapui")
  dap_package.listeners.after.event_initialized["dapui_config"] = function()
    dapui.open()
  end
  dap_package.listeners.before.event_terminated["dapui_config"] = function()
    dapui.close()
  end
  dap_package.listeners.before.event_exited["dapui_config"] = function()
    dapui.close()
  end
  dapui.setup(doom.features.dap.settings.dapui)
end

dap.configs["osv"] = function()
  local dap_package = require("dap")
  dap_package.configurations.lua = {
    {
      type = "nlua",
      request = "attach",
      name = "Attach to running Neovim instance",
    },
  }

  dap_package.adapters.nlua = function(callback, config)
    callback({ type = "server", host = config.host or "127.0.0.1", port = config.port or 8086 })
  end

  local adaptor_dir = "~/sources/local-lua-debugger-vscode/"
  dap_package.adapters["local-lua"] = {
    type = "executable",
    command = "node",
    args = {
      adaptor_dir .. "extension/debugAdapter.js",
    },
    enrich_config = function(config, on_config)
      if not config["extensionPath"] then
        local c = vim.deepcopy(config)
        -- 💀 If this is missing or wrong you'll see
        -- "module 'lldebugger' not found" errors in the dap-repl when trying to launch a debug session
        c.extensionPath = adaptor_dir
        on_config(c)
      else
        on_config(config)
      end
    end,
  }
end

dap.binds = {
  "<leader>",
  name = "+prefix",
  {
    {
      "d",
      name = "+debug",
      {
        {
          "c",
          function()
            require("dap").continue()
          end,
          name = "Continue/Start",
        },
        {
          "d",
          function()
            require("dap").disconnect()
          end,
          name = "Disconnect",
        },
        {
          "e",
          function()
            require("dapui").eval()
          end,
          name = "Evaluate",
        },
        {
          mode = "v",
          {
            {
              "e",
              function()
                require("dapui").eval()
              end,
              name = "Evaluate",
            },
          },
        },
        {
          "s",
          function()
            require("osv").launch({ port = 8086 })
          end,
          name = "Start NvimDebug",
        },
        {
          "b",
          name = "+breakpoint",
          {
            {
              "b",
              function()
                require("dap").toggle_breakpoint()
              end,
              name = "Toggle breakpoint",
            },
            {
              "c",
              function()
                vim.fn.inputsave()
                local condition = vim.fn.input("Condition: ")
                vim.fn.inputrestore()
                require("dap").toggle_breakpoint(condition)
              end,
              name = "Toggle",
            },
            {
              "h",
              function()
                vim.fn.inputsave()
                local number = vim.fn.input("Hit number: ")
                vim.fn.inputrestore()
                require("dap").toggle_breakpoint(nil, number)
              end,
              name = "Hit number",
            },
            {
              "l",
              function()
                vim.fn.inputsave()
                local msg = vim.fn.input("Message: ")
                vim.fn.inputrestore()
                require("dap").toggle_breakpoint(nil, nil, msg)
              end,
              name = "Log",
            },
            {
              "i",
              function()
                require("dap").step_into()
              end,
              name = "Step into",
            },
            {
              "o",
              function()
                require("dap").step_over()
              end,
              name = "Step over",
            },
          },
        },
      },
    },
    {
      "o",
      name = "+open",
      {
        {
          "d",
          function()
            require("dapui").toggle()
          end,
          name = "Debugger",
        },
      },
    },
  },
}

return dap

local dap = {}

local function lazy_load(plugins)
  local ok, lazy = pcall(require, "lazy")
  if ok then
    lazy.load { plugins = plugins }
  end
end

dap.settings = {
  debugger_dir = vim.fn.stdpath "data" .. "/dapinstall/",
  debugger_map = {},
  dapui = {
    icons = { expanded = "▾", collapsed = "▸" },
    mappings = {
      expand = { "<CR>", "<2-LeftMouse>" },
      open = "o",
      remove = "d",
      edit = "e",
      repl = "r",
    },
    layouts = {
      {
        elements = { "scopes", "breakpoints", "stacks", "watches" },
        size = 40,
        position = "left",
      },
      { elements = { "repl", "console" }, size = 10, position = "bottom" },
    },
  },
}

dap.packages = {
  ["nvim-dap"] = { "mfussenegger/nvim-dap", cmd = "DapContinue" },
  ["nvim-dap-ui"] = {
    "rcarriga/nvim-dap-ui",
    dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
    after = { "nvim-dap" },
    cmd = "DapContinue",
    lazy = true,
  },
  ["osv"] = {
    "jbyuki/one-small-step-for-vimkind",
    dependencies = { "mfussenegger/nvim-dap" },
    after = { "nvim-dap" },
    cmd = "DapContinue",
    lazy = true,
  },
}

dap.configs = {}
dap.configs["nvim-dap-ui"] = function()
  local dap_package = require "dap"
  local dapui = require "dapui"
  dap_package.listeners.after.event_initialized["dapui_config"] = function()
    dapui.open()
  end
  dap_package.listeners.before.event_terminated["dapui_config"] = function()
    dapui.close()
  end
  dap_package.listeners.before.event_exited["dapui_config"] = function()
    dapui.close()
  end
  dapui.setup(gentlewind.features.dap.settings.dapui)
end

dap.configs["osv"] = function()
  local dap_package = require "dap"
  dap_package.configurations.lua = {
    {
      type = "nlua",
      request = "attach",
      name = "Attach to running Neovim instance",
    },
  }

  dap_package.adapters.nlua = function(callback, config)
    callback {
      type = "server",
      host = config.host or "127.0.0.1",
      port = config.port or 8086,
    }
  end

  local adaptor_dir = "~/sources/local-lua-debugger-vscode/"
  dap_package.adapters["local-lua"] = {
    type = "executable",
    command = "node",
    args = { adaptor_dir .. "extension/debugAdapter.js" },
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
  { "<leader>", group = "prefix", {
    { "d", group = "debug", {
        { "c", function()
            lazy_load { "nvim-dap" }
            require("dap").continue()
          end, desc = "Continue/Start" },
        { "d", function()
            lazy_load { "nvim-dap" }
            require("dap").disconnect()
          end, desc = "Disconnect" },
        { "e", function()
            lazy_load { "nvim-dap", "nvim-dap-ui" }
            require("dapui").eval()
          end, desc = "Evaluate" },
        { mode = "v", {
            { "e", function()
                lazy_load { "nvim-dap", "nvim-dap-ui" }
                require("dapui").eval()
              end, desc = "Evaluate" },
          },
        },
        { "s", function()
            lazy_load { "nvim-dap", "one-small-step-for-vimkind" }
            require("osv").launch { port = 8086 }
          end, desc = "Start NvimDebug" },
        { "i", function()
            lazy_load { "nvim-dap" }
            require("dap").step_into()
          end, desc = "Step into" },
        { "o", function()
            lazy_load { "nvim-dap" }
            require("dap").step_over()
          end, desc = "Step over" },
        { "b", group = "breakpoint", {
            { "b", function()
                lazy_load { "nvim-dap" }
                require("dap").toggle_breakpoint()
              end, desc = "Toggle breakpoint" },
            { "c", function()
                lazy_load { "nvim-dap" }
                vim.fn.inputsave()
                local condition = vim.fn.input "Condition: "
                vim.fn.inputrestore()
                require("dap").toggle_breakpoint(condition)
              end, desc = "Toggle" },
            { "h", function()
                lazy_load { "nvim-dap" }
                vim.fn.inputsave()
                local number = vim.fn.input "Hit number: "
                vim.fn.inputrestore()
                require("dap").toggle_breakpoint(nil, number)
              end, desc = "Hit number" },
            { "l", function()
                lazy_load { "nvim-dap" }
                vim.fn.inputsave()
                local msg = vim.fn.input "Message: "
                vim.fn.inputrestore()
                require("dap").toggle_breakpoint(nil, nil, msg)
              end, desc = "Log" },
          },
        },
      },
    },
  }},
}

return dap

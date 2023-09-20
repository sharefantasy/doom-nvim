local explorer = {}

explorer.settings = {
  disable_netrw = true,
  hijack_netrw = true,
  open_on_setup = false,
  ignore_ft_on_setup = {},
  open_on_tab = true,
  hijack_cursor = true,
  update_cwd = true,
  respect_buf_cwd = true,
  update_focused_file = {
    enable = true,
    update_cwd = true,
    ignore_list = {},
  },
  view = {
    width = 35,
    side = "left",
    mappings = {
      custom_only = false,
    },
  },
  filters = {
    custom = { "^\\.git", "node_modules.editor", "^\\.cache", "__pycache__" },
  },
  renderer = {
    indent_markers = {
      enable = true,
    },
    highlight_git = true,
    root_folder_modifier = ":~",
    add_trailing = true,
    group_empty = true,
    special_files = {
      "README.md",
      "Makefile",
      "MAKEFILE",
    },
    icons = {
      glyphs = {
        default = "",
        symlink = "",
        folder = {
          arrow_open = "",
          arrow_closed = "",
          default = "",
          open = "",
          empty = "",
          empty_open = "",
          symlink = "",
          symlink_open = "",
        },
        git = {
          unstaged = "",
          staged = "",
          unmerged = "",
          renamed = "",
          untracked = "",
          deleted = "",
          ignored = "◌",
        },
      },
      show = {
        git = true,
        folder = true,
        file = true,
        folder_arrow = true,
      },
    },
  },
  actions = {
    open_file = {
      resize_window = true, -- previously view.auto_resize
      window_picker = {
        exclude = {
          filetype = {
            "notify",
            "packer",
            "qf",
          },
          buftype = {
            "terminal",
          },
        },
      },
    },
  },
  diagnostics = {
    enable = false,
  },
  -- use_tmux_integration = true
}

explorer.packages = {
  ["nvim-tree.lua"] = {
    "nvim-tree/nvim-tree.lua",
    cmd = {
      "NvimTreeClipboard",
      "NvimTreeClose",
      "NvimTreeFindFile",
      "NvimTreeOpen",
      "NvimTreeRefresh",
      "NvimTreeToggle",
    },
  },
  ["tmuxsend.vim"] = {
    "kiyoon/tmuxsend.vim",
  "kiyoon/nvim-tree-remote.nvim",
  },
  ["tmux.nvim"] = {
    "aserowy/tmux.nvim",
  }

}

explorer.configs = {}
explorer.configs["nvim-tree.lua"] = function()
  local utils = require("doom.utils")
  local is_module_enabled = utils.is_module_enabled
  local override_table = {}
  if is_module_enabled("features", "lsp") then
    override_table = {
      diagnostics = {
        enable = true,
        icons = {
          hint = doom.features.lsp.settings.icons.hint,
          info = doom.features.lsp.settings.icons.info,
          warning = doom.features.lsp.settings.icons.warn,
          error = doom.features.lsp.settings.icons.error,
        },
      },
    }
  end
  local config = vim.tbl_deep_extend("force", {
    view = {
      mappings = {
        list = {
          { key = { "o", "<2-LeftMouse>" }, cb = "edit" },
          { key = { "<CR>", "<2-RightMouse>", "<C-]>" }, cb = "cd" },
          { key = "<C-v>", cb = "vsplit" },
          { key = "<C-x>", cb = "split" },
          { key = "<C-t>", cb = "tabnew" },
          { key = "<BS>", cb = "close_node" },
          { key = "<S-CR>", cb = "close_node" },
          { key = "<Tab>", cb = "preview" },
          { key = "I", cb = "toggle_git_ignored" },
          { key = "H", cb = "toggle_dotfiles" },
          { key = "R", cb = "refresh" },
          { key = "a", cb = "create" },
          { key = "d", cb = "remove" },
          { key = "r", cb = "rename" },
          { key = "<C-r>", cb = "full_rename" },
          { key = "x", cb = "cut" },
          { key = "c", cb = "copy" },
          { key = "p", cb = "paste" },
          { key = "[c", cb = "prev_git_item" },
          { key = "]c", cb = "next_git_item" },
          { key = "-", cb = "dir_up" },
          { key = "q", cb = "close" },
          { key = "g?", cb = "toggle_help" },
          { "-", "<Plug>(tmuxsend-smart)", mode = { "n", "x" } },
          { "_", "<Plug>(tmuxsend-plain)", mode = { "n", "x" } },
          { "<space>-", "<Plug>(tmuxsend-uid-smart)", mode = { "n", "x" } },
          { "<space>_", "<Plug>(tmuxsend-uid-plain)", mode = { "n", "x" } },
          { "<C-_>", "<Plug>(tmuxsend-tmuxbuffer)", mode = { "n", "x" } },
        },
      },
    },
    filters = {
      dotfiles = not doom.show_hidden,
    },
    git = {
      ignore = doom.hide_gitignore,
    },
  }, doom.features.explorer.settings, override_table)
  require("nvim-tree").setup(config)
end


local function nvim_tree_on_attach(bufnr)
  local api = require "nvim-tree.api"
  local nt_remote = require "nvim_tree_remote"

  local function opts(desc)
    return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
  end

  api.config.mappings.default_on_attach(bufnr)

  vim.keymap.set("n", "u", api.tree.change_root_to_node, opts "Dir up")
  vim.keymap.set("n", "<F1>", api.node.show_info_popup, opts "Show info popup")
  vim.keymap.set("n", "l", nt_remote.tabnew, opts "Open in treemux")
  vim.keymap.set("n", "<CR>", nt_remote.tabnew, opts "Open in treemux")
  vim.keymap.set("n", "<C-t>", nt_remote.tabnew, opts "Open in treemux")
  vim.keymap.set("n", "<2-LeftMouse>", nt_remote.tabnew, opts "Open in treemux")
  vim.keymap.set("n", "h", api.tree.close, opts "Close node")
  vim.keymap.set("n", "v", nt_remote.vsplit, opts "Vsplit in treemux")
  vim.keymap.set("n", "<C-v>", nt_remote.vsplit, opts "Vsplit in treemux")
  vim.keymap.set("n", "<C-x>", nt_remote.split, opts "Split in treemux")
  vim.keymap.set("n", "o", nt_remote.tabnew_main_pane, opts "Open in treemux without tmux split")

  vim.keymap.set("n", "-", "", { buffer = bufnr })
  vim.keymap.del("n", "-", { buffer = bufnr })
  vim.keymap.set("n", "<C-k>", "", { buffer = bufnr })
  vim.keymap.del("n", "<C-k>", { buffer = bufnr })
  vim.keymap.set("n", "O", "", { buffer = bufnr })
  vim.keymap.del("n", "O", { buffer = bufnr })
end

explorer.configs["tmuxsend.vim"] = function()
      local nvim_tree = require "nvim-tree"

      nvim_tree.setup {
        on_attach = nvim_tree_on_attach,
        update_focused_file = {
          enable = true,
          update_cwd = true,
        },
        renderer = {
          --root_folder_modifier = ":t",
          icons = {
            glyphs = {
              default = "",
              symlink = "",
              folder = {
                arrow_open = "",
                arrow_closed = "",
                default = "",
                open = "",
                empty = "",
                empty_open = "",
                symlink = "",
                symlink_open = "",
              },
              git = {
                unstaged = "",
                staged = "S",
                unmerged = "",
                renamed = "➜",
                untracked = "U",
                deleted = "",
                ignored = "◌",
              },
            },
          },
        },
        diagnostics = {
          enable = true,
          show_on_dirs = true,
          icons = {
            hint = "",
            info = "",
            warning = "",
            error = "",
          },
        },
        view = {
          width = 30,
          side = "left",
        },
        filters = {
          custom = { ".git" },
        },
      }
end

explorer.configs["tmux.nvim"] = function()
      -- Navigate tmux, and nvim splits.
      -- Sync nvim buffer with tmux buffer.
      require("tmux").setup {
        copy_sync = {
          enable = true,
          sync_clipboard = false,
          sync_registers = true,
        },
        resize = {
          enable_default_keybindings = false,
        },
      }
end

explorer.binds = {
  { "<F3>", ":NvimTreeToggle<CR>", name = "Toggle file explorer" },
  {
    "<leader>",
    name = "+prefix",
    {
      {
        "o",
        name = "+open/close",
        {
          { "e", "<cmd>NvimTreeToggle<CR>", name = "Explorer" },
        },
      },
    },
  },
  { "<leader>",
    {
      {
        "p",
        {
          { "a", "<cmd>NvimTreeFindFile<CR>", name = "Show file in explorer" },
        },
      },
    },
  }
}

explorer.autocmds = {
  {
    "BufEnter",
    "*",
    function()
      local name = vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf())
      if vim.fn.isdirectory(name) == 1 then
        require("nvim-tree.api").tree.change_root(name)
      end
    end,
  },
}

return explorer

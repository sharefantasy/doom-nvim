local required = {}

required.settings = { mapper = {} }

required.packages = {
  ["lazy.nvim"] = {
    "folke/lazy.nvim",
  },
  ["plenary.nvim"] = {
    "nvim-lua/plenary.nvim",
  },
  ["nvim-web-devicons"] = {
    "kyazdani42/nvim-web-devicons",
  },
}

required.configs = {}

required.binds = function()
  local binds = {
    { "ZZ", require("doom.core.functions").quit_doom, desc = "Fast exit" },
    { "<ESC>", ":noh<CR>", desc = "Remove search highlight" },
    { "<Tab>", ":bnext<CR>", desc = "Jump to next buffer" },
    { "<S-Tab>", ":bprevious<CR>", desc = "Jump to prev buffer" },
    {
      "<C-",
      {
        { "h>", "<C-w>h", desc = "Jump window left" },
        { "j>", "<C-w>j", desc = "Jump window down" },
        { "k>", "<C-w>k", desc = "Jump window up" },
        { "l>", "<C-w>l", desc = "Jump window right" },
        {
          mode = "nv",
          {
            {
              "Left>",
              ":vertical resize -2<CR>",
              desc = "Resize window left",
            },
            { "Down>", ":resize -2<CR>", desc = "Resize window down" },
            { "Up>", ":resize +2<CR>", desc = "Resize window up" },
            {
              "Right>",
              ":vertical resize +2<CR>",
              desc = "Resize window right",
            },
          },
        },
      },
    },
    {
      "<a-",
      {
        { "j>", ":m .+1<CR>==", desc = "Move line down" },
        { "k>", ":m .-2<CR>==", desc = "Move line up" },
      },
    },
    {
      mode = "v",
      {
        {
          "<a-",
          {
            {
              "j>",
              ":m '<+1<CR>gv=gv",
              desc = "Move line down",
              mode = "v",
            },
            {
              "k>",
              ":m '<-2<CR>gv=gv",
              desc = "Move line up",
              mode = "v",
            },
          },
        },
        { ">", ">gv", mode = "v" }, -- Stay in visual after indent.
        { "<", "<gv", mode = "v" }, -- Stay in visual after indent.
      },
    },
    {
      mode = "i",
      {
        {
          "<a-",
          {
            {
              "j>",
              "<ESC>:m '<+1<CR>==gi",
              desc = "Move line down",
              mode = "i",
            },
            {
              "k>",
              "<ESC>:m '<-2<CR>==gi",
              desc = "Move line up",
              mode = "i",
            },
          },
        },
      },
    },
    {
      mode = "t",
      { { "<Esc>", "<C-\\><C-n>", desc = "Exit insert in terminal" } },
    },
  }

  -- Conditionally disable macros
  if doom.disable_macros then
    table.insert(binds, { "q", "<Nop>" })
  end
  -- Conditionally disable ex mode
  if doom.disable_ex then
    table.insert(binds, { "Q", "<Nop>" })
  end
  -- Conditionally disable suspension
  if doom.disable_suspension then
    table.insert(binds, { "<C-z>", "<Nop>" })
  end

  -- Exit insert mode fast
  for _, esc_seq in pairs(doom.escape_sequences) do
    table.insert(binds, { esc_seq, "<ESC>", mode = "i" })
  end

  local split_modes = { vertical = "vert ", horizontal = "", [false] = "e" }
  local split_prefix = split_modes[doom.new_file_split]
  table.insert(binds, {
    "<leader>",
    desc = "+prefix",
    {
      { "m", "<cmd>w<CR>", desc = "Write" },
      {
        "b",
        desc = "+buffer",
        {
          {
            "b",
            function()
              require("telescope.builtin").buffers {}
            end,
            desc = "List buffers",
          },
          { "d", "<cmd>bd<CR>", desc = "Delete" },
        },
      },
      {
        "D",
        desc = "+doom",
        {
          {
            "c",
            ("<cmd>e %s<CR>"):format(require("doom.core.config").source),
            desc = "Edit config",
          },
          {
            "m",
            ("<cmd>e %s<CR>"):format(require("doom.core.modules").source),
            desc = "Edit modules",
          },
          {
            "d",
            require("doom.core.functions").open_docs,
            desc = "Open documentation",
          },
          { "l", "<cmd>DoomReload<CR>", desc = "Reload config" },
          { "r", "<cmd>DoomRollback<CR>", desc = "Rollback" },
          { "R", "<cmd>DoomReport<CR>", desc = "Report issue" },
          { "u", "<cmd>DoomUpdate<CR>", desc = "Update" },
          { "s", "<cmd>Lazy sync<CR>", desc = "Sync packages" },
          { "I", "<cmd>Lazy install<CR>", desc = "Install packages" },
          { "C", "<cmd>Lazy clean<CR>", desc = "Clean packages" },
          -- { "b", "<cmd>Lazy build<CR>", desc = "Build packages" },
          { "p", "<cmd>Lazy profile<CR>", desc = "Profile" },
        },
      },
      {
        "f",
        desc = "+file",
        {
          {
            "n",
            (":%snew<CR>"):format(split_prefix),
            desc = "Create new",
          },
          { "w", "<cmd>w<CR>", desc = "Write" },
          {
            "W",
            function()
              vim.fn.inputsave()
              local new_name = vim.fn.input "New name: "
              vim.fn.inputrestore()
              vim.cmd("w " .. new_name)
            end,
            desc = "Write as",
          },
          { "s", "<cmd>w<CR>", desc = "Save" },
          {
            "S",
            function()
              vim.fn.inputsave()
              local new_name = vim.fn.input "New name: "
              vim.fn.inputrestore()
              vim.cmd("w " .. new_name)
            end,
            desc = "Save as",
          },
        },
      },
      {
        "h",
        desc = "+help",
        {
          {
            "h",
            "<cmd>Man<CR>",
            desc = "Manual pages",
            options = { silent = false },
          },
          { "D", "<cmd>DoomManual<CR>", desc = "Open Doom" },
        },
      },
      {
        "j",
        desc = "+jump",
        {
          { "a", "<C-^>", desc = "Alternate file" },
          { "j", "<C-o>", desc = "Older file" },
          { "k", "<C-i>", desc = "Newer file" },
          { "p", "<cmd>tag<CR>", desc = "Push tag" },
          { "P", "<cmd>pop<CR>", desc = "Pop tag" },
        },
      },
      {
        "q",
        desc = "+quit",
        {
          {
            "q",
            require("doom.core.functions").quit_doom,
            desc = "Exit and save",
          },
          {
            "w",
            require("doom.core.functions").quit_doom,
            desc = "Exit and save",
          },
          {
            "d",
            function()
              require("doom.core.functions").quit_doom(true, true)
            end,
            desc = "Exit and discard",
          },
        },
      },
      {
        "t",
        desc = "+tweak",
        {
          {
            "b",
            require("doom.core.functions").toggle_background,
            desc = "Toggle background",
          },
          {
            "s",
            require("doom.core.functions").toggle_signcolumn,
            desc = "Toggle sigcolumn",
          },
          {
            "i",
            require("doom.core.functions").set_indent,
            desc = "Set indent",
          },
          {
            "n",
            require("doom.core.functions").change_number,
            desc = "Toggle number",
          },
          {
            "S",
            require("doom.core.functions").toggle_spell,
            desc = "Toggle spelling",
          },
          {
            "x",
            require("doom.core.functions").change_syntax,
            desc = "Toggle syntax",
          },
        },
      },
      {
        "w",
        desc = "+window",
        {
          { "w", "<C-w>p", desc = "Jump to recent" },
          { "d", "<C-w>c", desc = "Delete window" },
          { "-", "<C-w>s", desc = "Split up/down" },
          { "|", "<C-w>v", desc = "Split left/right" },
          { "/", "<C-w>v", desc = "Split left/right" },
          { "s", "<C-w>s", desc = "Split up/down" },
          { "v", "<C-w>v", desc = "Split left/right" },
          { "h", "<C-w>h", desc = "Jump left" },
          { "j", "<C-w>j", desc = "Jump down" },
          { "k", "<C-w>k", desc = "Jump up" },
          { "l", "<C-w>l", desc = "Jump right" },
          { "H", "<C-w>H", desc = "Move left" },
          { "J", "<C-w>J", desc = "Move down" },
          { "K", "<C-w>K", desc = "Move up" },
          { "L", "<C-w>L", desc = "Move right" },
          { "=", "<C-w>=", desc = "Move right" },
          {
            "<C-",
            {
              { "H>", "<C-w>5<", desc = "Expand left" },
              { "J>", "<cmd>resize +5<CR>", desc = "Expand down" },
              { "K>", "<cmd>resize -5<CR>", desc = "Expand up" },
              { "L>", "<C-w>L", desc = "Expand right" },
            },
          },
        },
      },
    },
  })

  return binds
end

required.autocmds = function()
  local autocmds = {}

  if doom.autosave then
    table.insert(autocmds, { "TextChanged,InsertLeave", "<buffer>", "silent! write" })
  end

  if doom.highlight_yank then
    table.insert(autocmds, {
      "TextYankPost",
      "*",
      function()
        require("vim.hl").on_yank { higroup = "Search", timeout = 200 }
      end,
    })
  end

  if doom.preserve_edit_pos then
    table.insert(autocmds, {
      "BufReadPost",
      "*",
      [[if &ft !~# 'commit\|rebase' && line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif]],
    })
  end
  return autocmds
end

required.cmds = {
  {
    "DoomProfile",
    function(opts)
      local show_async = string.find(opts.args, "async") ~= nil
      require("doom.services.profiler").log { show_async = show_async }
    end,
    { nargs = "*" },
  },
}

return required

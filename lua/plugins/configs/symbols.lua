return function()
    G.symbols_outline = {
        highlight_hovered_item = true,
        show_guides = true,
        position = Doom.symbols_outline_left,
        keymaps = {
            close = '<Esc>',
            goto_location = '<CR>',
            focus_location = 'o',
            hover_symbol = '<C-space>',
            rename_symbol = 'r',
            code_actions = 'a',
        },
        lsp_blacklist = {},
    }
end

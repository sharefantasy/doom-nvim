local hurl = {}

hurl.settings = {}

hurl.packages = {["rest.nvim"] = {"pfeiferj/nvim-hurl"}}

hurl.configs = {}
hurl.configs["rest.nvim"] = function()
    require("rest-nvim").setup(doom.features.hurl.settings)
end

hurl.binds = {
    {
        "<leader>",
        name = "+prefix",
        {
            {
                "o",
                name = "+open/close",
                {{"h", "<cmd>RestNvim<CR>", name = "Http"}}
            }
        }
    }
}

return hurl

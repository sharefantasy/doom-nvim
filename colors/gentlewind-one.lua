vim.cmd("hi clear")
if vim.fn.exists("syntax_on") then vim.cmd("syntax reset") end

vim.g["colors_name"] = "gentlewind-one"

package.loaded["colors.gentlewind-one"] = nil
require("colors.gentlewind-one").load_colorscheme()

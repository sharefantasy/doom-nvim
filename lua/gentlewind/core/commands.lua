-- This file only has side-effects.
-- Gentlewind Nvim commands.
-- Set a custom command to open Gentlewind Nvim user manual can be called by using
-- :GentlewindManual.
vim.cmd([[command! GentlewindManual lua require("gentlewind.core.functions").open_docs()]])
-- Set a custom command to create a crash report can be called by using
-- :GentlewindReport.
vim.cmd(
    [[command! GentlewindReport lua require("gentlewind.core.functions").create_report(]])

vim.cmd(
    [[command! -nargs=* GentlewindNuke lua require("gentlewind.core.functions").nuke(<f-args>)]])

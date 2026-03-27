# Utils

Herein lies all the Gentlewind utility functions and variables.

## Variables

- `gentlewind_version` - Gentlewind Nvim version.
- `gentlewind_root` - Gentlewind Nvim root directory.
- `gentlewind_logs` - Gentlewind Nvim logs file path.
- `gentlewind_report` - Gentlewind Nvim crash report path.
- `git_workspace` - Gentlewind Nvim workspace for Git commands.

## Functions

- `map` - Wrapper for `nvim_set_keymap`.
- `create_augroups` - Autocommands wrapper for Lua.
- `is_empty` - Check if a string is empty or nil.
- `has_value` - Search if a table have a value.
- `get_os` - Get the current OS using LuaJIT.
- `read_file` - returns the content of the given file.
- `write_file` - writes the given string into given file.

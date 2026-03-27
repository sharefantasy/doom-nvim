# Core

The core workings of the gentlewind-nvim framework.

## Overview
- `init.lua` Entrypoint
- `gentlewind_global.lua` Sets the `gentlewind` global object including default settings and `use_*` style helper functions.
- `config.lua` Responsible for configuring gentlewind-nvim, will use the user's `modules.lua` and `config.lua`
- `modules.lua` Responsible for storing the enabled modules (user's `modules.lua` file) as well as later acting upon `gentlewind.modules` to set everything up.
- `functions.lua` Extra helper functions used internally by gentlewind-nvim.
- `commands.lua` Extra helper commands used internally by gentlewind-nvim.
- `ui.lua` Loads the user's colorscheme from the `gentlewind.colorscheme` field.  Falls back to `gentlewind-one` if a colorscheme isn't set or is broken.
Those modules are the following:
- `system.lua` Evaluates and caches some directories/filepaths to be used internally.

## Order of execution

1. `init.lua` requies `gentlewind_global.lua` to set the `gentlewind` global object.
2. `init.lua` loads `config.lua` which does the following
  a. Sets some default `vim.opt` options.
  b. Loads the user's enabled modules from `modules.lua`
  c. Adds all of these module objects to the `gentlewind.modules` field in the `gentlewind` global object.
  d. Runs the user's `config.lua` file (so the user can apply their config)
  e. Applies some of the settings in the `gentlewind` global object such as `gentlewind.indent`
3. `init.lua` loads `functions.lua` and `commands.lua` to set these extra functions/commands.
4. `init.lua` runs the `start`, `load_modules` and `handle_user_config` functions of `modules.lua` which does the following:
  a. Install/bootstrap packer on behalf of the user.
  b. `load_modules` will iterate over the `gentlewind.modules` field (set in `config.lua`), installing packer dependencies, binding autocmds and regular cmds.
  c. `handle_user_config` will handle the user imported packages, autocmds and vim cmds from the `use_*` functions (from user's `config.lua` file).

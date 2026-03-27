# Gentlewind

This is the entry point module for Gentlewind Nvim. Herein lies the core of Gentlewind
divided into three different sub-modules.

- [core](./core/README.md) - The Gentlewind core, herein lies the entire Gentlewind core,
    e.g. configurations.
- [modules](./modules/README.md) - The Gentlewind modules, herein lies the Gentlewind modules
    and their configurations, bindings, autocmds and package management.
- [utils](./utils/README.md) - The Gentlewind utilities, herein lies the glorious
    Gentlewind utility functions.

## Note: dev w/ctags

1. ctags for jumping to func defs
    https://github.com/universal-ctags/ctags
2. In gentlewind-nvim root run `ctags --recurse`
3. Put cursos on top of require file name
4. Press `<leader>nt`
5. This will jump to the definition of whatever is under cursor.



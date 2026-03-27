# Colors

This module contains the embedded colorschemes for Gentlewind Nvim and the utils
module required by those colorschemes.

Actually the embedded colorschemes are the following:

- gentlewind-one (dark and light variant)

## utils

The utils module contains a few utilities for easily port Gentlewind Emacs colorschemes
to Lua colorschemes. These utilities are the following:

- `Lighten` - lighten the provided HEX color in X percentage (5 by default).
- `Darken` - darken the provided HEX color in X percentage (5 by default).
- `Mix` - mix two provided HEX colors in X percentage (0 by default)

## Contributing

### Write colorschemes

If you want to write colorschemes for Gentlewind Nvim you will need to follow some
requirements.

- The colorscheme should be a Gentlewind Emacs colorscheme, see [emacs-gentlewind-themes].
- The colorscheme should be written in pure Lua **without using helpers like lush**,
  you can take a look at [gentlewind-one] source or use it as a template (highly recommended).

### Update embedded colorschemes

If you want to update the embedded colorschemes like [gentlewind-one] you'll need to
copy the gentlewind-one files to the proper locations and change a few lines to match
Gentlewind Nvim structure.

- Changes in `colors/gentlewind-one.lua`:

```lua
--- FROM:
package.loaded['gentlewind-one'] = nil
require('gentlewind-one')

--- TO:
package.loaded['colors.gentlewind-one'] = nil
require('colors.gentlewind-one')
```

- Changes in `gentlewind-one/init.lua`:

```lua
--- FROM:
local utils = require('utils')

--- TO:
local utils = require('colors.utils')
```

[gentlewind-one]: https://github.com/NTBBloodbath/gentlewind-one.nvim
[emacs-gentlewind-themes]: https://github.com/hlissner/emacs-gentlewind-themes

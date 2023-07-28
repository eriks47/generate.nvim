# generate.nvim

Generate C++ class method implementations.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Preview

https://github.com/eriks47/neoassist/assets/90338990/c91c8f67-1a25-4967-9972-9300e30bf9fc

## :sparkles: Features

- [x] Generate method implementations
- [x] Never delete anything
- [x] Multiple classes and namespaces in a file
- [x] Incremental implementation generation
- [ ] Declaration (header) generation
- [ ] User configuration support
- [ ] Handle nesting in namespaces
- [ ] Error handling
- [ ] Handle Windows paths
- [ ] Improved header to source mapping (see [ourboros.nvim](https://github.com/jakemason/ouroboros.nvim))
- [x] Filetype plugin

## :package: Installation

The plugin depends on [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter)
and the C++ parser, which can be installed via `:TSInstall cpp`

[lazy.nvim](https://github.com/folke/lazy.nvim):
```lua
require('lazy').setup({
  {
    'eriks47/generate.nvim',
    dependencies = { 'nvim-treesitter/nvim-treesitter' }
  }
})
```
[vim-plug](https://github.com/junegunn/vim-plug):
```vim
Plug 'nvim-treesitter/nvim-treesitter'
Plug 'eriks47/generate.nvim'
```

## :rocket: Usage

To generate method implementations simply run `:Generate implementations`
from the header file.

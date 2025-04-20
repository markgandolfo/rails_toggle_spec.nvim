# Rails Spec Finder

A simple Neovim plugin to quickly navigate between Rails implementation files and their corresponding spec files.

## Features

- Quickly toggle between implementation and spec files with a single command
- Works with standard Rails directory structures
- Handles multiple spec types (controller specs, request specs, model specs, etc.)
- Offers to create missing spec files with a basic template
- Automatically detects Rails project root using Git

## Installation

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  'markgandolfo/rails_toggle_spec.nvim',
  config = function()
    require('rails_toggle_spec').setup()
  end
}
```

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'markgandolfo/rails_toggle_spec.nvim',
  config = function()
    require('rails_toggle_spec').setup()
  end
}
```

### Using [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'markgandolfo/rails_toggle_spec.nvim'
```

Then add to your `init.vim` or `init.lua`:

```lua
lua require('rails_toggle_spec').setup()
```

## Usage

By default, the plugin maps `<Leader>s` to toggle between implementation and spec files.

You can also use the command:

```
:RailsToggleSpec
```

## Configuration

You can customize the plugin by passing options to the setup function:

```lua
require('rails_toggle_spec').setup({
  create_mappings = false -- Disable default keymappings
})
```

Then create your own mappings:

```lua
vim.api.nvim_set_keymap("n", "<Leader>rs", ":RailsToggleSpec<CR>", { noremap = true, silent = true })
```

## How It Works

The plugin will:

1. Identify if the current file is a Ruby implementation file or a spec file
2. Find the corresponding file based on standard Rails directory structure conventions
3. If the file exists, open it
4. If it doesn't exist but it's a spec, offer to create it with a basic template

## Supported File Types

- Controllers and their specs (both controller specs and request specs)
- Models and their specs
- Helpers and their specs
- Mailers and their specs
- Jobs and their specs
- Services and their specs
- Library files and their specs

## Contributing

Contributions are welcome! Feel free to open issues or submit pull requests.

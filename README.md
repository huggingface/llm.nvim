# 🤗 Hugging Face Code Completion for Neovim

**WIP**: this is a PoC at the moment

This Neovim client is like Copilot but you can pick your model on the Hugging Face Hub.

Heavily inspired by [copilot.lua](https://github.com/zbirenbaum/copilot.lua) and [tabnine-nvim](https://github.com/codota/tabnine-nvim)

## Install

Get your API token from here https://huggingface.co/settings/tokens.

### Using [vim-plug](https://github.com/junegunn/vim-plug)

*May not currently work*

1. Add the following in your `init.vim`

```vim
call plug#begin()
Plug 'huggingface/hfcc.nvim'
call plug#end()
```

2. Restart Neovim and run `:PlugInstall`

### Using [packer](https://github.com/wbthomason/packer.nvim)

*May not currently work*

1. Add the following in your `init.lua`:

```lua
require("packer").startup(function(use)
  use { 'huggingface/hfcc.nvim' }
end)
```

2. Restart Neovim and run `:PackerInstall`

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

1. Add the following in your `init.lua`:

```lua
require("lazy").setup({
  { 'huggingface/hfcc.nvim', opts = { api_token = "<insert your api token here>" } },
})
```

2. Restart Neovim and run `:Lazy`

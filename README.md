# 🤗 Hugging Face Code Completion for Neovim

**WIP**: this is a PoC at the moment

This Neovim client is like Copilot but you can pick your model on the Hugging Face Hub.

Heavily inspired by [copilot.lua](https://github.com/zbirenbaum/copilot.lua) and [tabnine-nvim](https://github.com/codota/tabnine-nvim)


![demonstration use of hfcc.nvim](assets/hfcc_demo.gif)

## Install

1. Get your API token from here https://huggingface.co/settings/tokens.

2. Choose your model on the [Hugging Face Hub](https://huggingface.co/)

### Using [packer](https://github.com/wbthomason/packer.nvim)

```lua
require("packer").startup(function(use)
  use {
    'huggingface/hfcc.nvim',
    config = function()
      require('hfcc').setup({
        api_token = "<insert your api token here>",
        model = "bigcode/starcoder" -- can be a model ID or an http endpoint
      })
    end
  }
end)
```

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
require("lazy").setup({
  {
    'huggingface/hfcc.nvim',
    opts = {
      api_token = "<insert your api token here>",
      model = "bigcode/starcoder" -- can be a model ID or an http endpoint
    }
  },
})
```

### Using [vim-plug](https://github.com/folke/lazy.nvim)
```vim
Plug 'huggingface/hfcc.nvim'
```
```lua
require('hfcc').setup({
        api_token = "<insert your api token here>",
        model = "bigcode/starcoder" -- can be a model ID or an http endpoint
      })
```

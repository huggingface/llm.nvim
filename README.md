# 🤗 Hugging Face Code Completion for Neovim

**WIP**: this is a PoC at the moment

This Neovim client is like Copilot but you can pick your model on the Hugging Face Hub.

Heavily inspired by [copilot.lua](https://github.com/zbirenbaum/copilot.lua) and [tabnine-nvim](https://github.com/codota/tabnine-nvim)


![demonstration use of hfcc.nvim](assets/hfcc_demo.gif)

## Install

1. Create and get your API token from here https://huggingface.co/settings/tokens.

2. Define how the plugin will read your token. For this you have multiple options, in order of precedence:
    1. Pass `api_token = <your token>` in plugin opts - this is not recommended if you use a versioning tool for your configuration files
    2. Set the `HUGGING_FACE_HUB_TOKEN` environment variable
    3. You can define your `HF_HOME` environment variable and create a file containing your token at `$HF_HOME/token`
    4. Install the [huggingface-cli](https://huggingface.co/docs/huggingface_hub/quick-start) and run `huggingface-cli login` - this will prompt you to enter your token and set it at the right path

3. Choose your model on the [Hugging Face Hub](https://huggingface.co/)

### Using [packer](https://github.com/wbthomason/packer.nvim)

```lua
require("packer").startup(function(use)
  use {
    'huggingface/hfcc.nvim',
    config = function()
      require('hfcc').setup({
        -- cf Setup
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
      -- cf Setup
    }
  },
})
```

### Using [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'huggingface/hfcc.nvim'
```
```lua
require('hfcc').setup({
  -- cf Setup
})
```

## Setup

```lua
local hfcc = require('hfcc')

hfcc.setup({
  api_token = "", -- cf Install paragraph
  model = "bigcode/starcoder" -- can be a model ID or an http(s) endpoint
  -- parameters that are added to the request body
  query_params = {
    max_new_tokens = 60,
    temperature = 0.2,
    top_p = 0.95,
    stop_token = "<|endoftext|>",
  },
  -- set this if the model supports fill in the middle
  fim = {
    enabled = true,
    prefix = "<fim_prefix>",
    middle = "<fim_middle>",
    suffix = "<fim_suffix>",
  },
})
```

## Commands

There are currently two commands:
- `HFccSuggestion` which was left in case people depended on it, depending on feedback will probably be removed
- `HFccToggleAutoSuggest` which enables/disables insert mode suggest-as-you-type suggestions


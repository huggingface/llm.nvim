# LLM powered development for Neovim

> [!IMPORTANT]
> This is currently a work in progress.

**llm.nvim** is a plugin for all things LLM-related.

This project is influenced by [copilot.vim](https://github.com/github/copilot.vim) and [tabnine-nvim](https://github.com/codota/tabnine-nvim)

Formerly **hfcc.nvim**.

![demonstration use of llm.nvim](assets/llm_nvim_demo.gif)

## Features

### Code completion

This plugin supports code completion "ghost-text" style, a la Copilot.


**llm.nvim** is an autocompletion plugin similar to Copilot with the added benefit of letting you pick your model on the Hugging Face Hub.

You can also use any HTTP endpoint you want, provided it adheres to the API specified [here](https://huggingface.co/docs/api-inference/detailed_parameters#text-generation-task).

You can also use it in conjunction with [llm-ls]() a language server where new features and development will happen.

You can use it as a standalone plugin that will curl a model on the Hugging Face Hub or the API of your choice.

## Install

1. Create and get your API token from here https://huggingface.co/settings/tokens.

2. Define how the plugin will read your token. For this you have multiple options, in order of precedence:
    1. Pass `api_token = <your token>` in plugin opts - this is not recommended if you use a versioning tool for your configuration files
    2. Set the `LLM_NVIM_API_TOKEN` environment variable
    3. You can define your `HF_HOME` environment variable and create a file containing your token at `$HF_HOME/token`
    4. Install the [huggingface-cli](https://huggingface.co/docs/huggingface_hub/quick-start) and run `huggingface-cli login` - this will prompt you to enter your token and set it at the right path

3. Choose your model on the [Hugging Face Hub](https://huggingface.co/), and, in order of precedence, you can either:
    1. Set the `LLM_NVIM_MODEL` environment variable
    2. Pass `model = <model token>` in plugin opts

### Using [packer](https://github.com/wbthomason/packer.nvim)

```lua
require("packer").startup(function(use)
  use {
    'huggingface/llm.nvim',
    config = function()
      require('llm').setup({
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
    'huggingface/llm.nvim',
    opts = {
      -- cf Setup
    }
  },
})
```

### Using [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'huggingface/llm.nvim'
```
```lua
require('llm').setup({
  -- cf Setup
})
```

## Setup

```lua
local llm = require('llm')

llm.setup({
  api_token = nil, -- cf Install paragraph
  model = "bigcode/starcoder", -- can be a model ID or an http(s) endpoint
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
  debounce_ms = 80,
  accept_keymap = "<Tab>",
  dismiss_keymap = "<S-Tab>",
  max_context_after = 5000,
  max_context_before = 5000,
  tls_skip_verify_insecure = false,
})
```

## Commands

- `LLMToggleAutoSuggest` which enables/disables insert mode suggest-as-you-type suggestions


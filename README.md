# LLM powered development for Neovim

> [!IMPORTANT]
> This is currently a work in progress, expect things to be broken!

**llm.nvim** is a plugin for all things LLM. It uses [**llm-ls**](https://github.com/huggingface/llm-ls) as a backend.

This project is influenced by [copilot.vim](https://github.com/github/copilot.vim) and [tabnine-nvim](https://github.com/codota/tabnine-nvim)

Formerly **hfcc.nvim**.

![demonstration use of llm.nvim](assets/llm_nvim_demo.gif)

## Features

### Code completion

This plugin supports "ghost-text" code completion, à la Copilot.

### Choose your model

Requests for code generation are made via an HTTP request.

You can use the Hugging Face [Inference API](https://huggingface.co/inference-api) or your own HTTP endpoint, provided it adheres to the API specified [here](https://huggingface.co/docs/api-inference/detailed_parameters#text-generation-task) or [here](https://huggingface.github.io/text-generation-inference/#/Text%20Generation%20Inference/generate).

### Always fit within the context window

The prompt sent to the model will always be sized to fit within the context window, with the number of tokens determined using [tokenizers](https://github.com/huggingface/tokenizers).

## Configuration

### Endpoint

#### With Inference API

1. Create and get your API token from here https://huggingface.co/settings/tokens.

2. Define how the plugin will read your token. For this you have multiple options, in order of precedence:
    1. Pass `api_token = <your token>` in plugin opts - this is not recommended if you use a versioning tool for your configuration files
    2. Set the `LLM_NVIM_API_TOKEN` environment variable
    3. You can define your `HF_HOME` environment variable and create a file containing your token at `$HF_HOME/token`
    4. Install the [huggingface-cli](https://huggingface.co/docs/huggingface_hub/quick-start) and run `huggingface-cli login` - this will prompt you to enter your token and set it at the right path

3. Choose your model on the [Hugging Face Hub](https://huggingface.co/), and, in order of precedence, you can either:
    1. Set the `LLM_NVIM_MODEL` environment variable
    2. Pass `model = <model identifier>` in plugin opts

#### With your own HTTP endpoint

All of the above still applies, but note:

* When `api_token` is set, it will be passed as a header: `Authorization: Bearer <api_token>`.

* Instead of setting a Hugging Face model identifier in `model`, set the URL for your HTTP endpoint.

### Models

#### [Starcoder](https://huggingface.co/bigcode/starcoder)

```lua
{
  tokens_to_clear = { "<|endoftext|>" },
  fim = {
    enabled = true,
    prefix = "<fim_prefix>",
    middle = "<fim_middle>",
    suffix = "<fim_suffix>",
  },
  model = "bigcode/starcoder",
  context_window = 8192,
  tokenizer = {
    repository = "bigcode/starcoder",
  }
}
```

> [!NOTE]
> These are the default config values

#### [CodeLlama](https://huggingface.co/codellama/CodeLlama-13b-hf)

```lua
{
  tokens_to_clear = { "<EOT>" },
  fim = {
    enabled = true,
    prefix = "<PRE> ",
    middle = " <MID>",
    suffix = " <SUF>",
  },
  model = "codellama/CodeLlama-13b-hf",
  context_window = 4096,
  tokenizer = {
    repository = "codellama/CodeLlama-13b-hf",
  }
}
```

> [!NOTE]
> Spaces are important here

### [**llm-ls**](https://github.com/huggingface/llm-ls)

By default, **llm-ls** is installed by **llm.nvim** the first time it is loaded. The binary is downloaded from the [release page](https://github.com/huggingface/llm-ls/releases) and stored in:
```lua
vim.api.nvim_call_function("stdpath", { "data" }) .. "/llm_nvim/bin"
```

When developing locally, when using mason or if you built your own binary because your platform is not supported, you can set the `lsp.bin_path` setting to the path of the binary.

`lsp.version` is used only when **llm.nvim** downloads **llm-ls** from the release page.

#### Mason

You can install **llm-ls** via [mason.nvim](https://github.com/williamboman/mason.nvim). To do so, run the following command:

```vim
:MasonInstall llm-ls
```

Then reference **llm-ls**'s path in your configuration:

```lua
{
  -- ...
  lsp = {
    bin_path = vim.api.nvim_call_function("stdpath", { "data" }) .. "/mason/bin/llm-ls",
  },
  -- ...
}
```
### Tokenizer

**llm-ls** uses [**tokenizers**](https://github.com/huggingface/tokenizers) to make sure the prompt fits the `context_window`.

To configure it, you have a few options:
* No tokenization, **llm-ls** will count the number of characters instead:
```lua
{
  tokenizer = nil,
}
```
* from a local file on your disk:
```lua
{
  tokenizer = {
    path = "/path/to/my/tokenizer.json"
  }
}
```
* from a Hugging Face repository, **llm-ls** will attempt to download `tokenizer.json` at the root of the repository:
```lua
{
  tokenizer = {
    repository = "myusername/myrepo"
  }
}
```
* from an HTTP endpoint, **llm-ls** will attempt to download a file via an HTTP GET request:
```lua
{
  tokenizer = {
    url = "https://my-endpoint.example.com/mytokenizer.json",
    to = "/download/path/of/mytokenizer.json"
  }
}
```

### Package manager

#### Using [packer](https://github.com/wbthomason/packer.nvim)

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

#### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

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

#### Using [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'huggingface/llm.nvim'
```
```lua
require('llm').setup({
  -- cf Setup
})
```

### Setup

```lua
local llm = require('llm')

llm.setup({
  api_token = nil, -- cf Install paragraph
  model = "bigcode/starcoder", -- can be a model ID or an http(s) endpoint
  tokens_to_clear = { "<|endoftext|>" }, -- tokens to remove from the model's output
  -- parameters that are added to the request body
  query_params = {
    max_new_tokens = 60,
    temperature = 0.2,
    top_p = 0.95,
    stop_tokens = nil,
  },
  -- set this if the model supports fill in the middle
  fim = {
    enabled = true,
    prefix = "<fim_prefix>",
    middle = "<fim_middle>",
    suffix = "<fim_suffix>",
  },
  debounce_ms = 150,
  accept_keymap = "<Tab>",
  dismiss_keymap = "<S-Tab>",
  tls_skip_verify_insecure = false,
  -- llm-ls configuration, cf llm-ls section
  lsp = {
    bin_path = nil,
    version = "0.2.1",
  },
  tokenizer = nil, -- cf Tokenizer paragraph
  context_window = 8192, -- max number of tokens for the context window
  enable_suggestions_on_startup = true,
})

```

## Commands

- `LLMToggleAutoSuggest` which enables/disables ghost text completion


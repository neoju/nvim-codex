# nvim-codex

Send file context from Neovim to an open [Codex CLI](https://github.com/openai/codex)
session in tmux.

`nvim-codex` turns the current line or visual selection into a location-aware
prompt, then places it in the matching Codex pane. It is intentionally small:
you keep working in Neovim, while Codex receives the exact place you want to
discuss.

## Requirements

- Neovim 0.10 or later
- [tmux](https://github.com/tmux/tmux)
- [Codex CLI](https://github.com/openai/codex), running in a tmux pane

Neovim and Codex must be in the same tmux window. The Codex pane must be
running in the same working directory as Neovim. The plugin finds panes by
their current command (`codex`) and current directory.

## Installation

With [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "neoju/nvim-codex",
}
```

With [packer.nvim](https://github.com/wbthomason/packer.nvim):

```lua
use({
  "neoju/nvim-codex",
  config = function()
    require("nvimcodex").setup()
  end,
})
```

## Usage

1. Start Neovim and Codex in separate panes of the same tmux window, both in
   the project directory.
2. In Neovim, place the cursor on a line or select lines in Visual mode.
3. Press `<C-a>` and enter your request.
4. The plugin writes a prompt such as `lua/nvimcodex/init.lua:L35 - explain
this function` into the Codex pane and focuses it.
5. Press `<Enter>` in Codex to submit the prompt.

In Normal mode, the current line is sent. In Visual mode, the selected line
range is sent. The plugin uses `Snacks.input()` when
[snacks.nvim](https://github.com/folke/snacks.nvim) is available; otherwise it
uses Neovim's built-in `vim.ui.input()`.

If no matching Codex pane is found, the plugin shows a warning. Check that
Codex is running, that both panes share a tmux window, and that their working
directories match.

## Configuration

The default setup is enough for most users:

```lua
require("nvimcodex").setup()
```

Available options:

```lua
require("nvimcodex").setup({
  debug = false,
})
```

Set `debug = true` to enable diagnostic notifications.

## Commands and API

`:Nvimcodex` toggles the plugin's internal enabled state. The public Lua API is
also available through `require("nvimcodex")`:

```lua
local codex = require("nvimcodex")

codex.send_to_codex()
codex.enable()
codex.disable()
codex.toggle()
```

Run `:help Nvimcodex.options` for the generated option documentation.

## Contributing

Run the test suite with:

```sh
make test
```

Please include a focused description and reproduction steps with bug reports.

## License

[MIT](LICENSE)

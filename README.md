# nvim-codex

Send file context from Neovim to an open [Codex CLI](https://github.com/openai/codex)
session in tmux.

`nvim-codex` turns the current line or visual selection into a location-aware
prompt, then places it in the matching Codex pane. It is intentionally small:
you keep working in Neovim, while Codex receives the exact place you want to
discuss.

## Requirements

- Neovim 0.10.1 or later
- [snacks.nvim](https://github.com/folke/snacks.nvim)
- [tmux](https://github.com/tmux/tmux)
- [Codex CLI](https://github.com/openai/codex), running in a tmux pane
- [blink.cmp](https://github.com/Saghen/blink.cmp) (optional, for prompt completion)

Neovim and Codex must be in the same tmux window. The Codex pane must be
running in the same working directory as Neovim. The plugin finds panes by
their current command (`codex`) and current directory.

## Installation

With [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "neoju/nvim-codex",
  dependencies = { "folke/snacks.nvim" },
}
```

With [packer.nvim](https://github.com/wbthomason/packer.nvim):

```lua
use({
  "neoju/nvim-codex",
  requires = { "folke/snacks.nvim" },
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
this function` into the Codex pane.
5. By default, the plugin submits the prompt automatically. Set `auto_send` to
   `false` if you want to press `<Enter>` in Codex yourself, and enable
   `auto_focus_codex` if you also want to switch focus to the Codex pane.

In Normal mode, the current line is sent. In Visual mode, the selected line
range is sent. The plugin uses `Snacks.input()` for prompts; `snacks.nvim` is a
required dependency.

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
  auto_send = true,
  auto_focus_codex = false,
  keymap = "<C-a>",
})
```

Available options:

- `debug`: Set to `true` to enable diagnostic notifications. Defaults to
  `false`.
- `auto_send`: Press `<Enter>` in the Codex pane after sending the prompt.
  Defaults to `true`.
- `auto_focus_codex`: Focus the Codex pane after sending the prompt. Defaults
  to `false`.
- `keymap`: Normal/Visual mode mapping that opens the prompt. Defaults to
  `"<C-a>"`; set to `false` to disable the mapping.

## Completion

If [blink.cmp](https://github.com/Saghen/blink.cmp) is installed, the ask
prompt enables completion automatically (the buffer uses the `nvimcodex_ask`
filetype with only this plugin's source active):

- `$<name>` completes Codex skills scanned from `<cwd>/.codex/skills`,
  `<cwd>/.agents/skills`, `$CODEX_HOME/skills` (or `~/.codex/skills`, including
  `.system/` built-ins), `~/.agents/skills`, and
  `$CODEX_HOME/plugins/cache/*/*/*/skills` (plugin skills, lowest precedence).
  Directories are scanned in
  that order and the first occurrence of a skill name wins, so project skills
  shadow user ones. Entries may be symlinks. Skills are scanned the first time
  the prompt opens and re-scanned after `DirChanged`; force a rescan with
  `:lua require("nvimcodex").reload_skills()`.
- `@buffer` targets the whole current file (relative path, no line range).
- `@ask` tells Codex to answer the request without editing files.
- `@explain` tells Codex to explain the selected code and its surrounding context without editing files.

If automatic registration does not work with your blink.cmp setup, configure
the source manually:

```lua
require("blink.cmp").setup({
  sources = {
    per_filetype = {
      nvimcodex_ask = { "nvimcodex" },
    },
    providers = {
      nvimcodex = {
        name = "NvimCodex",
        module = "nvimcodex.integrations.blink",
      },
    },
  },
})
```

## Commands and API

`:Nvimcodex` opens the prompt. The public Lua API is also available through
`require("nvimcodex")`:

```lua
local codex = require("nvimcodex")

codex.setup()
codex.send()
codex.send_to_codex() -- alias of send()
codex.reload_skills()
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

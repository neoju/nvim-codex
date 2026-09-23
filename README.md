# nvim-codex

`nvim-codex` sends your current line or Visual selection, with its file
location, to an open [Codex CLI](https://github.com/openai/codex) session in
tmux. Write a request in Neovim and send it to the matching Codex pane without
copying code or file paths by hand.

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
  dependencies = {
    "folke/snacks.nvim",
    "saghen/blink.cmp", -- optional, for prompt completion
  },
}
```

With [packer.nvim](https://github.com/wbthomason/packer.nvim):

```lua
use({
  "neoju/nvim-codex",
  requires = {
    "folke/snacks.nvim",
    "saghen/blink.cmp", -- optional, for prompt completion
  },
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

### Examples

Update later

## Configuration

With LazyVim, add `lua/plugins/nvim-codex.lua`:

```lua
return {
  "neoju/nvim-codex",
  dependencies = {
    "folke/snacks.nvim",
    "saghen/blink.cmp", -- optional, for prompt completion
  },
  opts = {
    debug = false,
    auto_send = true,
    auto_focus_codex = false,
    keymap = "<C-a>",
  },
}
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

If [blink.cmp](https://github.com/Saghen/blink.cmp) is installed, completion is
registered automatically for the prompt. Available entries are:

| Entry | Purpose |
| --- | --- |
| `$<skill>` | Include a Codex skill. Project skills take precedence over user and plugin skills. |
| `@buffer` | Target the current file, without a line range. |
| `@ask` | Ask Codex to answer without editing files. |
| `@diagnose` | Investigate a problem and report its cause without editing files. |
| `@explain` | Ask Codex to explain the selected code and its surrounding context. |
| `@fix` | Diagnose, fix, and verify the reported behavior. |
| `@test` | Add meaningful tests for selected behavior and report coverage. |
| `#brief` | Keep the response brief. |
| `#readonly` | Prevent file edits for the current task. |
| `#scoped` | Attach an edit boundary to the current task. |

For definition syntax and task behavior, see [Prompt definitions](doc/prompt-definitions.md).

Skills are loaded when the prompt first opens and refreshed after `DirChanged`.
To rescan them manually, run `:lua require("nvimcodex").reload_skills()`.

If automatic registration does not work with your blink.cmp setup, add this
LazyVim plugin spec to `lua/plugins/blink.lua`:

```lua
return {
  "saghen/blink.cmp",
  opts = {
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
  },
}
```

## Commands and API

`:Nvimcodex` opens the prompt. The public Lua API is also available through
`require("nvimcodex")`:

```lua
local codex = require("nvimcodex")

codex.setup()
codex.send()
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

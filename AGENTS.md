# Repository Guidelines

## Project Structure & Module Organization

The plugin entry point is `plugin/nvimcodex.lua`; implementation lives under `lua/nvimcodex/`. Prompt parsing and rendering are in `prompt/`, the Snacks input window is in `ui/`, tmux delivery is in `transport/`, and optional integrations are in `integrations/`. Markdown command and modifier definitions live in `lua/nvimcodex/prompt/definitions/`. Tests are in `tests/test_*.lua`, with shared helpers in `tests/helpers.lua`. User documentation is in `README.md` and generated Neovim help files under `doc/`; the GIFs in `doc/` illustrate usage.

## Build, Test, and Development Commands

There is no compilation step. Use `make test` to run the MiniTest suite in headless Neovim; the Makefile fetches `mini.nvim` into `deps/` for this workflow. Use `make lint` to format Lua with StyLua and run Luacheck. Use `make documentation` to regenerate help files, and `make luals-ci` to check Lua language server diagnostics when the server is installed. For a manual check, run Neovim and Codex CLI in separate panes of the same tmux window and directory, then open the prompt with `<C-a>`.

## Coding Style & Naming Conventions

Use four spaces for Lua indentation and follow `stylua.toml` (100-column target, double quotes preferred). Keep modules under the `nvimcodex` namespace and name test files `test_<area>.lua`. Add prompt commands or modifiers as one Markdown file per token in the matching `definitions/` directory. Keep the public API and generated help text in sync with behavior changes.

## Testing Guidelines

Tests use `mini.test` and child Neovim instances initialized by `scripts/minimal_init.lua`. Add focused cases beside the affected module's existing tests, such as `tests/test_commands.lua` for prompt parsing or `tests/test_tmux.lua` for delivery. No coverage threshold is defined. Run `make test` before submitting, and check the real Neovim/tmux flow for changes to input or sending behavior.

## Commit & Pull Request Guidelines

Recent commits use short Conventional Commit subjects, such as `feat: add task-based prompt definitions and modifiers` and `fix: submit tmux prompt after trailing command`. Keep commits focused and include related tests. Pull requests should provide a concise summary using `.github/PULL_REQUEST_TEMPLATE.md`, link relevant issues when applicable, and include a screenshot or GIF for visual changes. Confirm tests, lint, and generated docs are current before requesting review.

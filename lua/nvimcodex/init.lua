local main = require("nvimcodex.main")
local config = require("nvimcodex.config")
local log = require("nvimcodex.util.log")

local tmux = require("nvimcodex.lib.tmux")
local input = require("nvimcodex.lib.input")

local Nvimcodex = {}

--- Toggle the plugin by calling the `enable`/`disable` methods respectively.
function Nvimcodex.toggle()
    if _G.Nvimcodex.config == nil then
        _G.Nvimcodex.config = config.options
    end

    main.toggle("public_api_toggle")
end

--- Initializes the plugin, sets event listeners and internal state.
function Nvimcodex.enable(scope)
    if _G.Nvimcodex.config == nil then
        _G.Nvimcodex.config = config.options
    end

    main.toggle(scope or "public_api_enable")
end

--- Disables the plugin, clear highlight groups and autocmds, closes side buffers and resets the internal state.
function Nvimcodex.disable()
    main.toggle("public_api_disable")
end

-- setup Nvimcodex options and merge them with user provided ones.
function Nvimcodex.setup(opts)
    _G.Nvimcodex.config = config.setup(opts)
end

function Nvimcodex.send_to_codex()
    local filepath = vim.fn.expand("%:.")
    local start_line
    local end_line

    if vim.fn.mode():match("^[vV\022]") then
        start_line = vim.fn.line("'<")
        end_line = vim.fn.line("'>")

        if start_line > end_line then
            start_line, end_line = end_line, start_line
        end
    else
        start_line = vim.fn.line(".")
        end_line = start_line
    end

    local location = start_line == end_line and string.format("%s:L%d", filepath, start_line)
        or string.format("%s:L%d-L%d", filepath, start_line, end_line)

    input.open({
        prompt = "Ask Codex: ",
        win = {
            relative = "cursor",
            row = 1,
            col = 0,
        },
    }, function(value)
        if value == nil then
            return -- User cancelled
        end

        local text = string.format("%s - %s", location, value)

        local sent, error_message = tmux.send_to_codex(text, vim.fn.getcwd())
        if not sent then
            log.notify("send_to_codex", vim.log.levels.WARN, true, "%s", error_message)
        end
    end)
end

_G.Nvimcodex = Nvimcodex

return _G.Nvimcodex

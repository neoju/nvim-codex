local input = {}

local blink_registered = false

local function set_default_highlights()
    if vim.fn.hlexists("NvimCodexInputCommand") == 0 then
        vim.api.nvim_set_hl(0, "NvimCodexInputCommand", { fg = "#ff8080", ctermfg = 9 })
    end
    if vim.fn.hlexists("NvimCodexInputModifier") == 0 then
        vim.api.nvim_set_hl(0, "NvimCodexInputModifier", { fg = "#ffbf80", ctermfg = 11 })
    end
    if vim.fn.hlexists("NvimCodexInputSkill") == 0 then
        vim.api.nvim_set_hl(0, "NvimCodexInputSkill", { fg = "#80bfff", ctermfg = 12 })
    end
end

local function highlights(text)
    local result = {}
    for start_col, token in text:gmatch("()(@[%w_:-]+)") do
        table.insert(result, { start_col - 1, start_col - 1 + #token, "NvimCodexInputCommand" })
    end
    for start_col, token in text:gmatch("()(#[%w_:-]+)") do
        table.insert(result, { start_col - 1, start_col - 1 + #token, "NvimCodexInputModifier" })
    end
    for start_col, token in text:gmatch("()(%$[%w_:-]+)") do
        table.insert(result, { start_col - 1, start_col - 1 + #token, "NvimCodexInputSkill" })
    end
    return result
end

--- Registers the `nvimcodex` blink.cmp source and enables it (exclusively) for
--- the `nvimcodex_ask` filetype. Idempotent and a no-op when blink is absent.
local function register_blink()
    if blink_registered then
        return
    end
    blink_registered = true

    local ok, blink = pcall(require, "blink.cmp")
    if not ok then
        return
    end

    local config = require("blink.cmp.config")
    if config.sources.providers.nvimcodex == nil then
        blink.add_source_provider("nvimcodex", {
            name = "NvimCodex",
            module = "nvimcodex.integrations.blink",
        })
    end
    -- per_filetype_provider_ids only *extends* the default sources; a
    -- user-style per_filetype entry is what restricts the ask buffer to our
    -- source alone. Set both for compatibility across blink versions.
    require("blink.cmp.sources.lib").per_filetype_provider_ids["nvimcodex_ask"] = { "nvimcodex" }
    if config.sources.per_filetype["nvimcodex_ask"] == nil then
        config.sources.per_filetype["nvimcodex_ask"] = { "nvimcodex" }
    end
end

function input.open(on_confirm)
    local ok, snacks = pcall(require, "snacks")
    if not ok then
        vim.notify("[nvimcodex.nvim] snacks.nvim is required for input", vim.log.levels.ERROR)
        return
    end

    require("nvimcodex.skills").ensure_loaded()
    register_blink()
    set_default_highlights()

    local opts = {
        prompt = "Ask Codex: ",
        icon_pos = "title",
        expand = false,
        highlight = highlights,
        win = {
            relative = "cursor",
            height = 2,
            bo = { filetype = "nvimcodex_ask" },
            b = { completion = true },
            on_buf = function(win)
                pcall(vim.api.nvim_buf_set_name, win.buf, "NvimCodexAsk")
            end,
        },
    }

    snacks.input(opts, on_confirm)
end

return input

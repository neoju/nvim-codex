local input = {}

local blink_registered = false

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

function input.open(opts, on_confirm)
    local ok, snacks = pcall(require, "snacks")
    if not ok then
        vim.notify("[nvimcodex.nvim] snacks.nvim is required for input", vim.log.levels.ERROR)
        return
    end

    require("nvimcodex.skills").ensure_loaded()
    register_blink()

    opts.win = vim.tbl_deep_extend("force", opts.win or {}, {
        bo = { filetype = "nvimcodex_ask" },
        b = { completion = true },
        on_buf = function(win)
            pcall(vim.api.nvim_buf_set_name, win.buf, "NvimCodexAsk")
        end,
    })

    snacks.input(opts, on_confirm)
end

return input

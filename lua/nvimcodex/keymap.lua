local config = require("nvimcodex.config")

local M = {}

local applied_key = nil

--- Applies the configured `keymap` option, removing the previously applied
--- mapping first so repeated `setup()` calls switch keys cleanly.
function M.apply()
    if applied_key ~= nil then
        pcall(vim.keymap.del, { "n", "x" }, applied_key)
        applied_key = nil
    end

    local key = config.options.keymap
    if type(key) == "string" then
        vim.keymap.set({ "n", "x" }, key, function()
            require("nvimcodex").send()
        end, { desc = "Send current context to Codex" })
        applied_key = key
    end
end

return M

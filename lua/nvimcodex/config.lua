local M = {}

--- Nvimcodex configuration with its default values.
---@tag Nvimcodex.options
---@eval return MiniDoc.afterlines_to_code(MiniDoc.current.eval_section)
M.options = {
    -- Prints useful logs about what event are triggered, and reasons actions are executed.
    debug = false,

    -- Auto trigger Enter key after send user's input to Codex pane
    auto_send = true,

    -- Auto focus to Codex pane after input
    auto_focus_codex = false,

    -- Normal/Visual mode mapping that opens the prompt. Set to `false` to disable.
    keymap = "<C-a>",
}

---@private
local defaults = vim.deepcopy(M.options)

--- Define your nvimcodex setup.
---
---@param options table Module config table. See |Nvimcodex.options|.
---
---@usage `require("nvimcodex").setup()` (add `{}` with your |Nvimcodex.options| table)
function M.setup(options)
    M.options = vim.tbl_deep_extend("keep", vim.deepcopy(options or {}), defaults)

    -- let your user know that they provided a wrong value, this is reported when your plugin is executed.
    assert(type(M.options.debug) == "boolean", "`debug` must be a boolean (`true` or `false`).")
    assert(
        M.options.keymap == false or type(M.options.keymap) == "string",
        "`keymap` must be a string or `false`."
    )

    return M.options
end

return M

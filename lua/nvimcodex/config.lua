local log = require("nvimcodex.util.log")

local Nvimcodex = {}

--- Nvimcodex configuration with its default values.
---
---@type table
--- Default values:
---@eval return MiniDoc.afterlines_to_code(MiniDoc.current.eval_section)
Nvimcodex.options = {
    -- Prints useful logs about what event are triggered, and reasons actions are executed.
    debug = false,

    -- Auto trigger Enter key after send user's input to Codex pane
    auto_send = false,

    -- Auto focus to Codex pane after input
    auto_focus_codex = false,
}

---@private
local defaults = vim.deepcopy(Nvimcodex.options)

--- Defaults Nvimcodex options by merging user provided options with the default plugin values.
---
---@param options table Module config table. See |Nvimcodex.options|.
---
---@private
function Nvimcodex.defaults(options)
    Nvimcodex.options = vim.deepcopy(vim.tbl_deep_extend("keep", options or {}, defaults or {}))

    -- let your user know that they provided a wrong value, this is reported when your plugin is executed.
    assert(
        type(Nvimcodex.options.debug) == "boolean",
        "`debug` must be a boolean (`true` or `false`)."
    )

    return Nvimcodex.options
end

--- Define your nvimcodex setup.
---
---@param options table Module config table. See |Nvimcodex.options|.
---
---@usage `require("nvimcodex").setup()` (add `{}` with your |Nvimcodex.options| table)
function Nvimcodex.setup(options)
    Nvimcodex.options = Nvimcodex.defaults(options or {})

    log.warn_deprecation(Nvimcodex.options)

    return Nvimcodex.options
end

return Nvimcodex

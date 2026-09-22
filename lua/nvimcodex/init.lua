local config = require("nvimcodex.config")
local keymap = require("nvimcodex.keymap")
local skills = require("nvimcodex.skills")

local Nvimcodex = {}

--- Setup Nvimcodex options and merge them with user provided ones.
---
---@param opts table Module config table. See |Nvimcodex.options|.
function Nvimcodex.setup(opts)
    config.setup(opts)
    keymap.apply()
end

--- Opens the prompt and sends the result to the Codex pane.
function Nvimcodex.send()
    require("nvimcodex.prompt").send()
end

--- Rescans the skill directories and refreshes the completion cache.
function Nvimcodex.reload_skills(callback)
    skills.reload(callback)
end

return Nvimcodex

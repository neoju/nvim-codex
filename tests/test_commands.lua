local Helpers = dofile("tests/helpers.lua")

local child = Helpers.new_child_neovim()

local T = MiniTest.new_set({
    hooks = {
        pre_case = function()
            child.restart({ "-u", "scripts/minimal_init.lua" })
            child.lua([[
                local commands = require("nvimcodex.lib.commands")
                _G.apply = function(text)
                    local ctx, cleaned = commands.apply({
                        filepath = "lua/foo.lua",
                        location = "lua/foo.lua:L3",
                    }, text)
                    return { location = ctx.location, prefix = ctx.prefix, text = cleaned }
                end
            ]])
        end,
        post_once = child.stop,
    },
})

T["commands.apply()"] = MiniTest.new_set()

T["commands.apply()"]["@buffer targets the whole file"] = function()
    local result = child.lua_get([[_G.apply("@buffer explain this")]])
    Helpers.expect.equality(result.location, "lua/foo.lua")
    Helpers.expect.equality(result.text, "explain this")
end

T["commands.apply()"]["@ask prepends the read-only prefix"] = function()
    local result = child.lua_get([[_G.apply("@ask what does this do")]])
    Helpers.expect.equality(
        result.prefix,
        table.concat({
            "[read-only]",
            "Context: The preceding location identifies the active Neovim file or selection.",
            "Goal: Answer the request below.",
            "Constraint: Do not modify files.",
        }, "\n")
    )
    Helpers.expect.equality(result.location, "lua/foo.lua:L3")
    Helpers.expect.equality(result.text, "what does this do")
end

T["commands.apply()"]["keeps unknown @tokens"] = function()
    local result = child.lua_get([[_G.apply("@foo explain this")]])
    Helpers.expect.equality(result.text, "@foo explain this")
    Helpers.expect.equality(result.location, "lua/foo.lua:L3")
    Helpers.expect.equality(child.lua_get([[_G.apply("@foo explain this").prefix == nil]]), true)
end

T["commands.apply()"]["leaves $skill tokens untouched"] = function()
    local result = child.lua_get([[_G.apply("use $gamma here")]])
    Helpers.expect.equality(result.text, "use $gamma here")
end

T["commands.apply()"]["applies multiple tokens"] = function()
    local result = child.lua_get([[_G.apply("@buffer @ask summarize")]])
    Helpers.expect.equality(result.location, "lua/foo.lua")
    Helpers.expect.equality(
        result.prefix,
        table.concat({
            "[read-only]",
            "Context: The preceding location identifies the active Neovim file or selection.",
            "Goal: Answer the request below.",
            "Constraint: Do not modify files.",
        }, "\n")
    )
    Helpers.expect.equality(result.text, "summarize")
end

return T

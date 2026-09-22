local Helpers = dofile("tests/helpers.lua")

local child = Helpers.new_child_neovim()

local ask_prefix = table.concat({
    "Goal: Answer the request below.",
    "Constraint: Do not modify files.",
}, "\n")

local explain_prefix = table.concat({
    "Goal: Explain the selected code and the surrounding implementation needed to understand it.",
    "Include: its purpose, control flow, relevant callers or dependencies, and effects.",
    "Constraint: Do not modify files.",
}, "\n")

local T = MiniTest.new_set({
    hooks = {
        pre_case = function()
            child.restart({ "-u", "scripts/minimal_init.lua" })
            child.lua([[
                local commands = require("nvimcodex.lib.commands")
                _G.apply = function(text)
                    local ctx = commands.apply({
                        filepath = "lua/foo.lua",
                        location = "lua/foo.lua:L3",
                    }, text)
                    return { location = ctx.location, prefix = ctx.prefix, text = ctx.value }
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

T["commands.apply()"]["@ask wraps the request as a read-only question"] = function()
    local result = child.lua_get([[_G.apply("@ask what does this do")]])
    Helpers.expect.equality(result.prefix, ask_prefix)
    Helpers.expect.equality(result.location, "lua/foo.lua:L3")
    Helpers.expect.equality(result.text, "Question: what does this do")
end

T["commands.apply()"]["@explain clears the text and sets an explanation goal"] = function()
    local result = child.lua_get([[_G.apply("@explain this function")]])
    Helpers.expect.equality(result.prefix, explain_prefix)
    Helpers.expect.equality(result.location, "lua/foo.lua:L3")
    Helpers.expect.equality(result.text, "")
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
    Helpers.expect.equality(result.prefix, ask_prefix)
    Helpers.expect.equality(result.text, "Question: summarize")
end

T["commands.format()"] = MiniTest.new_set()

T["commands.format()"]["renders location, prefix, value and subfix in order"] = function()
    local result = child.lua_get([[
        require("nvimcodex.lib.commands").format({
            location = "lua/foo.lua:L3",
            prefix = "Goal: Answer.",
            value = "request",
            subfix = "trailing",
        })
    ]])

    Helpers.expect.equality(result, "Context: lua/foo.lua:L3\nGoal: Answer.\nrequest\ntrailing")
end

T["commands.format()"]["skips the context line when location is empty"] = function()
    local result = child.lua_get([[
        require("nvimcodex.lib.commands").format({
            location = "",
            value = "request",
        })
    ]])

    Helpers.expect.equality(result, "request")
end

T["commands.format()"]["expands a Neo-tree visual selection into a file list"] = function()
    child.lua([[
        local paths = {
            [2] = vim.fn.getcwd() .. "/src/main.lua",
            [3] = vim.fn.getcwd() .. "/tests/test_main.lua",
        }

        package.loaded["neo-tree.sources.manager"] = {
            get_state = function(source)
                assert(source == "filesystem")
                return {
                    tree = {
                        get_node = function(_, line)
                            return paths[line] and { path = paths[line] } or nil
                        end,
                    },
                }
            end,
        }

        vim.fn.setpos("'<", { 0, 2, 1, 0 })
        vim.fn.setpos("'>", { 0, 3, 1, 0 })

        _G.formatted = require("nvimcodex.lib.commands").format({
            filepath = "neo-tree filesystem [1]",
            location = "neo-tree filesystem [1]:L2-L3",
            value = "request",
        })
    ]])
    local result = child.lua_get("_G.formatted")

    Helpers.expect.equality(result, "Context: \n  - src/main.lua\n  - tests/test_main.lua\nrequest")
end

return T

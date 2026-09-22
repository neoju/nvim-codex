local Helpers = dofile("tests/helpers.lua")

local child = Helpers.new_child_neovim()

local T = MiniTest.new_set({
    hooks = {
        pre_case = function()
            child.restart({ "-u", "scripts/minimal_init.lua", "--noplugin" })
        end,
        post_once = child.stop,
    },
})

T["format.render()"] = MiniTest.new_set()

T["format.render()"]["renders location, prefix, value and subfix in order"] = function()
    local result = child.lua_get([[
        require("nvimcodex.prompt.format").render({
            location = "lua/foo.lua:L3",
            prefix = "Goal: Answer.",
            value = "request",
            subfix = "trailing",
        })
    ]])

    Helpers.expect.equality(result, "Context: lua/foo.lua:L3\nGoal: Answer.\nrequest\ntrailing")
end

T["format.render()"]["skips the context line when location is empty"] = function()
    local result = child.lua_get([[
        require("nvimcodex.prompt.format").render({
            location = "",
            value = "request",
        })
    ]])

    Helpers.expect.equality(result, "request")
end

T["format.render()"]["renders a file list when ctx.files is set"] = function()
    local result = child.lua_get([[
        require("nvimcodex.prompt.format").render({
            files = { "src/main.lua", "tests/test_main.lua" },
            value = "request",
        })
    ]])

    Helpers.expect.equality(result, "Context: \n  - src/main.lua\n  - tests/test_main.lua\nrequest")
end

return T

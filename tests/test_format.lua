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

T["format.render()"]["renders General before higher-priority attributes"] = function()
    local result = child.lua_get([[
        require("nvimcodex.prompt.format").render({
            {
                location = "lua/foo.lua:L3",
                value = "request",
                attributes = {
                    goal = "Answer this.",
                    output = "A summary.",
                    boundaries = "Do not edit.",
                },
                special_instruction = "Edit the file.",
            },
        })
    ]])

    Helpers.expect.equality(
        result,
        table.concat({
            "<INSTRUCTIONS>",
            "General: Edit the file.",
            "Goal: Answer this.",
            "Output: A summary.",
            "Boundaries: Do not edit.",
            "Context:",
            "- lua/foo.lua:L3",
            "</INSTRUCTIONS>",
            "",
            "<USER_PROMPT>",
            "request",
            "</USER_PROMPT>",
        }, "\n")
    )
end

T["format.render()"]["returns a plain request without instructions"] = function()
    local result = child.lua_get([[
        require("nvimcodex.prompt.format").render({ { location = "", value = "request" } })
    ]])
    Helpers.expect.equality(result, "request")
end

T["format.render()"]["keeps multiline General text inside its section"] = function()
    local result = child.lua_get([[
        require("nvimcodex.prompt.format").render({
            {
                value = "request",
                special_instruction = "First line.\n\nGoal: This is still general text.\nLast line.",
                attributes = { goal = "This is the primary goal." },
            },
        })
    ]])
    Helpers.expect.equality(
        result,
        "<INSTRUCTIONS>\nGeneral: First line.\n  \n  Goal: This is still general text.\n  Last line.\nGoal: This is the primary goal.\n</INSTRUCTIONS>\n\n<USER_PROMPT>\nrequest\n</USER_PROMPT>"
    )
end

T["format.render()"]["renders file lists in Context"] = function()
    local result = child.lua_get([[
        require("nvimcodex.prompt.format").render({
            { files = { "src/main.lua", "tests/test_main.lua" }, value = "request" },
        })
    ]])
    Helpers.expect.equality(
        result,
        "<INSTRUCTIONS>\nContext:\n- src/main.lua\n- tests/test_main.lua\n</INSTRUCTIONS>\n\n<USER_PROMPT>\nrequest\n</USER_PROMPT>"
    )
end

T["format.render()"]["keeps each task's attributes and skills separate"] = function()
    local result = child.lua_get([[(function()
        local tasks = require("nvimcodex.prompt.commands").apply({
            filepath = "lua/foo.lua",
            location = "lua/foo.lua:L3",
        }, "@buffer #scoped $review-agent @ask why")
        return require("nvimcodex.prompt.format").render(tasks)
    end)()]])

    local blocks =
        vim.split(result, "\n---------------------------------------------\n", { plain = true })
    Helpers.expect.equality(#blocks, 2)
    Helpers.expect.equality(blocks[1]:find("Context:\n- lua/foo.lua", 1, true) ~= nil, true)
    Helpers.expect.equality(
        blocks[1]:find("Boundaries: Only edit within the provided context.", 1, true) ~= nil,
        true
    )
    Helpers.expect.equality(blocks[1]:find("Skills:\n- $review-agent", 1, true) ~= nil, true)
    Helpers.expect.equality(
        blocks[2]:find("Goal: Answer the user's question.", 1, true) ~= nil,
        true
    )
    Helpers.expect.equality(
        blocks[2]:find("Boundaries: Do not modify files.", 1, true) ~= nil,
        true
    )
    Helpers.expect.equality(blocks[2]:find("#scoped", 1, true), nil)
    Helpers.expect.equality(blocks[2]:find("Skills:", 1, true), nil)
end

return T

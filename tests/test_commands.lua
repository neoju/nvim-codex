local Helpers = dofile("tests/helpers.lua")

local child = Helpers.new_child_neovim()

local ask_attributes = {
    goal = "Answer the user's question.",
    output = "A direct answer to the question.",
    boundaries = "Do not modify files.",
}
local explain_attributes = {
    goal = "Explain the selected code and the surrounding implementation.",
    output = "Describe its purpose, control flow, relevant callers or dependencies, and effects.",
    boundaries = "Do not modify files.",
}
local scoped_boundary =
    "Only edit within the provided context. Do not modify code or files outside it."

local T = MiniTest.new_set({
    hooks = {
        pre_case = function()
            child.restart({ "-u", "scripts/minimal_init.lua" })
            child.lua([[
                local commands = require("nvimcodex.prompt.commands")
                _G.apply = function(text)
                    return commands.apply({
                        filepath = "lua/foo.lua",
                        location = "lua/foo.lua:L3",
                    }, text)
                end
            ]])
        end,
        post_once = child.stop,
    },
})

T["commands.apply()"] = MiniTest.new_set()

T["commands.apply()"]["returns one task without a command"] = function()
    Helpers.expect.equality(child.lua_get([[_G.apply("plain request")]]), {
        { value = "plain request", location = "lua/foo.lua:L3", skills = {} },
    })
end

T["commands.apply()"]["@buffer targets the whole file"] = function()
    local result = child.lua_get([[_G.apply("@buffer explain this")]])
    Helpers.expect.equality(#result, 1)
    Helpers.expect.equality(result[1].location, "lua/foo.lua")
    Helpers.expect.equality(result[1].value, "explain this")
end

T["commands.apply()"]["@ask wraps the request as a read-only question"] = function()
    local result = child.lua_get([[_G.apply("@ask what does this do")]])
    Helpers.expect.equality(result[1].attributes, ask_attributes)
    Helpers.expect.equality(result[1].location, "")
    Helpers.expect.equality(result[1].value, "what does this do")
end

T["commands.apply()"]["loads diagnosis, fix, and test presets"] = function()
    local result = child.lua_get([[_G.apply("@diagnose @fix @test failing behavior")]])
    Helpers.expect.equality(#result, 3)
    Helpers.expect.equality(
        result[1].attributes.goal,
        "Diagnose the reported behavior and identify its cause."
    )
    Helpers.expect.equality(result[1].attributes.boundaries, "Do not modify files.")
    Helpers.expect.equality(result[2].attributes.goal, "Fix the reported behavior.")
    Helpers.expect.equality(
        result[3].attributes.goal,
        "Add meaningful tests for the selected behavior and report what they cover."
    )
end

T["commands.apply()"]["#brief replaces output while #readonly keeps other attributes"] = function()
    local result = child.lua_get([[_G.apply("@fix #brief #readonly failing behavior")]])
    Helpers.expect.equality(result[1].attributes.goal, "Fix the reported behavior.")
    Helpers.expect.equality(result[1].attributes.output, "Keep the response brief.")
    Helpers.expect.equality(result[1].attributes.boundaries, "Do not modify files.")
end

T["commands.apply()"]["#scoped keeps @ask read-only with selected files"] = function()
    local result = child.lua_get([[(function()
        return require("nvimcodex.prompt.commands").apply({
            filepath = "lua/foo.lua",
            location = "lua/foo.lua:L3",
            files = { "one.lua" },
        }, "@ask #scoped what does this do")
    end)()]])
    Helpers.expect.equality(result[1].location, "")
    Helpers.expect.equality(result[1].files, { "one.lua" })
    Helpers.expect.equality(
        result[1].attributes.boundaries,
        "Do not modify files. " .. scoped_boundary
    )
end

T["commands.apply()"]["#readonly does not duplicate an existing read-only boundary"] = function()
    local result = child.lua_get([[_G.apply("@ask #readonly what does this do")]])
    Helpers.expect.equality(result[1].attributes.boundaries, "Do not modify files.")
end

T["commands.apply()"]["@ask without a question logs an error and cancels the prompt"] = function()
    child.lua([[
        _G.notifications = {}
        vim.notify = function(message, level)
            table.insert(_G.notifications, { message = message, level = level })
        end
        _G.empty_ask = require("nvimcodex.prompt.commands").apply({
            filepath = "lua/foo.lua",
            location = "lua/foo.lua:L3",
        }, "@ask   ")
    ]])

    Helpers.expect.equality(child.lua_get("_G.empty_ask == nil"), true)
    Helpers.expect.equality(child.lua_get("#_G.notifications"), 1)
    Helpers.expect.equality(child.lua_get("_G.notifications[1].level"), vim.log.levels.ERROR)
    Helpers.expect.equality(
        child.lua_get("_G.notifications[1].message"),
        "[nvimcodex.nvim@commands] @ask requires a question"
    )
end

T["commands.apply()"]["@explain clears the text and sets an explanation goal"] = function()
    local result = child.lua_get([[_G.apply("@explain this function")]])
    Helpers.expect.equality(result[1].attributes, explain_attributes)
    Helpers.expect.equality(result[1].location, "lua/foo.lua:L3")
    Helpers.expect.equality(result[1].value, "")
end

T["commands.apply()"]["keeps unknown @tokens"] = function()
    local result = child.lua_get([[_G.apply("@foo explain this")]])
    Helpers.expect.equality(result[1].value, "@foo explain this")
    Helpers.expect.equality(result[1].location, "lua/foo.lua:L3")
    Helpers.expect.equality(
        child.lua_get([[_G.apply("@foo explain this")[1].special_instruction == nil]]),
        true
    )
end

T["commands.apply()"]["moves $skill tokens into instructions"] = function()
    local result = child.lua_get([[_G.apply("use $my-skill here")]])
    Helpers.expect.equality(result[1].value, "use here")
    Helpers.expect.equality(result[1].skills, { "$my-skill" })
end

T["commands.apply()"]["applies multiple tokens"] = function()
    local result = child.lua_get([[_G.apply("@buffer @ask summarize")]])
    Helpers.expect.equality(result, {
        {
            value = "summarize",
            location = "lua/foo.lua",
            skills = {},
        },
        {
            attributes = ask_attributes,
            special_instruction = "Explain the reasoning when it helps answer the question.",
            value = "summarize",
            location = "",
            skills = {},
        },
    })
end

T["commands.apply()"]["attaches scoped instructions only to its command"] = function()
    local result = child.lua_get([[_G.apply("@buffer #scoped @ask @explain summarize $my-skill")]])
    Helpers.expect.equality(result, {
        {
            attributes = { boundaries = scoped_boundary },
            value = "summarize",
            location = "lua/foo.lua",
            skills = {},
        },
        {
            attributes = ask_attributes,
            special_instruction = "Explain the reasoning when it helps answer the question.",
            value = "summarize",
            location = "",
            skills = {},
        },
        {
            attributes = explain_attributes,
            value = "",
            location = "lua/foo.lua:L3",
            skills = { "$my-skill" },
        },
    })
end

T["commands.apply()"]["binds each skill to its task command"] = function()
    local result = child.lua_get([[_G.apply("@buffer $review-agent @ask What time is it?")]])
    Helpers.expect.equality(result[1].skills, { "$review-agent" })
    Helpers.expect.equality(result[2].skills, {})
end

T["commands.apply()"]["keeps file lists separate between tasks"] = function()
    local result = child.lua_get([[(function()
        local tasks = require("nvimcodex.prompt.commands").apply({
            filepath = "lua/foo.lua",
            location = "",
            files = { "one.lua" },
        }, "@buffer @ask request")
        tasks[1].files[1] = "changed.lua"
        return tasks[2].files[1]
    end)()]])
    Helpers.expect.equality(result, "one.lua")
end

T["commands.apply()"]["#scoped before @buffer attaches to the first task"] = function()
    local result = child.lua_get([[_G.apply("#scoped @buffer change this")]])
    Helpers.expect.equality(result[1].location, "lua/foo.lua")
    Helpers.expect.equality(result[1].value, "change this")
    Helpers.expect.equality(result[1].attributes.boundaries, scoped_boundary)
end

T["commands.apply()"]["#scoped attaches without creating a task"] = function()
    local result = child.lua_get([[_G.apply("@buffer #scoped change this")]])
    Helpers.expect.equality(#result, 1)
    Helpers.expect.equality(result[1].name, nil)
    Helpers.expect.equality(result[1].location, "lua/foo.lua")
    Helpers.expect.equality(result[1].value, "change this")
    Helpers.expect.equality(result[1].attributes.boundaries, scoped_boundary)
    Helpers.expect.equality(result[1].special_instruction, nil)
end

T["commands.apply()"]["modifier composes boundaries without changing special instructions"] = function()
    child.lua([[
        require("nvimcodex.prompt.commands").list.example = {
            primary_goal = "Do the requested work.",
            primary_boundaries = "Keep existing safeguards.",
            special_instruction = "Follow project conventions.",
        }
    ]])
    local result = child.lua_get([[_G.apply("@example #scoped change this")]])
    Helpers.expect.equality(result[1].attributes.goal, "Do the requested work.")
    Helpers.expect.equality(
        result[1].attributes.boundaries,
        "Keep existing safeguards. " .. scoped_boundary
    )
    Helpers.expect.equality(result[1].special_instruction, "Follow project conventions.")
end

T["commands.apply()"]["keeps names from the wrong namespace in the request"] = function()
    local result = child.lua_get([[_G.apply("@scoped #ask #buffer #explain #unknown change this")]])
    Helpers.expect.equality(result[1].name, nil)
    Helpers.expect.equality(result[1].value, "@scoped #ask #buffer #explain #unknown change this")
end

return T

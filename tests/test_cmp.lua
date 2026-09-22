local Helpers = dofile("tests/helpers.lua")

local child = Helpers.new_child_neovim()

local T = MiniTest.new_set({
    hooks = {
        pre_case = function()
            child.restart({ "-u", "scripts/minimal_init.lua" })
            child.lua([[
                _G.source = require("nvimcodex.cmp.blink").new()
                _G.get = function(line, start_col)
                    local result
                    _G.source:get_completions(
                        { line = line, bounds = { start_col = start_col } },
                        function(response)
                            result = response
                        end
                    )
                    return result
                end
            ]])
        end,
        post_once = child.stop,
    },
})

T["blink source"] = MiniTest.new_set()

T["blink source"]["$ trigger yields skill items"] = function()
    child.lua([[
        local skills = require("nvimcodex.lib.skills")
        skills.get = function()
            return {
                { name = "alpha", description = "Alpha skill", path = "/x/SKILL.md", root = "/x" },
            }
        end
    ]])

    local result = child.lua_get([[_G.get("hi $", 5)]])
    Helpers.expect.equality(#result.items, 1)
    local item = result.items[1]
    Helpers.expect.equality(item.label, "$alpha")
    Helpers.expect.equality(item.insertText, "$alpha")
    Helpers.expect.equality(item.filterText, "$alpha")
    Helpers.expect.equality(item.documentation, nil)
    Helpers.expect.equality(item.labelDetails.description, "Alpha skill")
    Helpers.expect.equality(result.is_incomplete_forward, false)
    Helpers.expect.equality(result.is_incomplete_backward, false)
end

T["blink source"]["@ trigger yields command items"] = function()
    local result = child.lua_get([[_G.get("@", 2)]])
    local labels = vim.tbl_map(function(item)
        return item.label
    end, result.items)
    Helpers.expect.equality(labels, { "@ask", "@buffer", "@explain" })
    Helpers.expect.equality(result.items[1].documentation, nil)
    Helpers.expect.equality(
        result.items[1].labelDetails.description,
        require("nvimcodex.lib.commands").list.ask.description
    )
end

T["blink source"]["other text yields no items"] = function()
    local result = child.lua_get([[_G.get("abc", 1)]])
    Helpers.expect.equality(result.items, {})
end

return T

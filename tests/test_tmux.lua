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

T["tmux.send_to_codex()"] = MiniTest.new_set()

T["tmux.send_to_codex()"]["pastes multiline prompts through a tmux buffer"] = function()
    child.lua([[
        local calls = {}
        local cwd = vim.fn.getcwd()
        local original_system = vim.system
        vim.system = function(command)
            table.insert(calls, command)
            return {
                wait = function()
                    if command[2] == "list-panes" then
                        return { code = 0, stdout = string.format("%%1\tcodex\t%s\n", cwd) }
                    end
                    return { code = 0, stderr = "" }
                end,
            }
        end

        local sent = require("nvimcodex.lib.tmux").send_to_codex("first\nsecond", cwd)
        vim.system = original_system
        _G.calls = calls
        _G.sent = sent
    ]])

    Helpers.expect.equality(child.lua_get("_G.sent"), true)
    local calls = child.lua_get("_G.calls")
    Helpers.expect.equality(calls[2][2], "set-buffer")
    Helpers.expect.equality(calls[2][6], "first\nsecond")
    Helpers.expect.equality(calls[3][2], "paste-buffer")
    Helpers.expect.equality(calls[3][3], "-d")
end

return T

local Helpers = dofile("tests/helpers.lua")

local child = Helpers.new_child_neovim()

local stub_neotree = [[
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

    vim.bo.filetype = "neo-tree"
]]

local T = MiniTest.new_set({
    hooks = {
        pre_case = function()
            child.restart({ "-u", "scripts/minimal_init.lua", "--noplugin" })
            child.lua([[
                vim.api.nvim_buf_set_name(0, vim.fn.getcwd() .. "/lua/foo.lua")
                vim.api.nvim_buf_set_lines(0, 0, -1, false, { "one", "two", "three" })
                vim.keymap.set("x", "<F9>", function()
                    _G.ctx = require("nvimcodex.prompt").capture()
                end)
            ]])
        end,
        post_once = child.stop,
    },
})

T["prompt.capture()"] = MiniTest.new_set()

T["prompt.capture()"]["captures the filepath in normal mode"] = function()
    local ctx = child.lua_get([[require("nvimcodex.prompt").capture()]])

    Helpers.expect.equality(ctx.filepath, "lua/foo.lua")
    Helpers.expect.equality(ctx.location, "")
end

T["prompt.capture()"]["captures a visual line range"] = function()
    child.type_keys("ggVj<F9>")
    local ctx = child.lua_get("_G.ctx")

    Helpers.expect.equality(ctx.filepath, "lua/foo.lua")
    Helpers.expect.equality(ctx.location, "lua/foo.lua:L1-L2")
end

T["prompt.capture()"]["captures the cursor line node in neo-tree (normal mode)"] = function()
    child.lua(stub_neotree)
    child.lua([[vim.api.nvim_win_set_cursor(0, { 2, 0 })]])
    local ctx = child.lua_get([[require("nvimcodex.prompt").capture()]])

    Helpers.expect.equality(ctx.files, { "src/main.lua" })
    Helpers.expect.equality(ctx.filepath, "")
    Helpers.expect.equality(ctx.location, "")
end

T["prompt.capture()"]["captures a visual selection of neo-tree nodes"] = function()
    child.lua(stub_neotree)
    child.type_keys("2GVj<F9>")
    local ctx = child.lua_get("_G.ctx")

    Helpers.expect.equality(ctx.files, { "src/main.lua", "tests/test_main.lua" })
    Helpers.expect.equality(ctx.filepath, "")
    Helpers.expect.equality(ctx.location, "")
end

return T

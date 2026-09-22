local Helpers = dofile("tests/helpers.lua")

-- See https://github.com/echasnovski/mini.nvim/blob/main/lua/mini/test.lua for more documentation

local child = Helpers.new_child_neovim()

local T = MiniTest.new_set({
    hooks = {
        -- This will be executed before every (even nested) case
        pre_case = function()
            -- Restart child process with custom 'init.lua' script
            child.restart({ "-u", "scripts/minimal_init.lua" })
        end,
        -- This will be executed one after all tests from this set are finished
        post_once = child.stop,
    },
})

-- Tests related to the `setup` method.
T["setup()"] = MiniTest.new_set()

T["plugin loading"] = MiniTest.new_set()

T["plugin loading"]["maps <C-a> in normal and visual mode without setup"] = function()
    Helpers.expect.global(
        child,
        "vim.fn.maparg('<C-a>', 'n', false, true).desc",
        "Send current context to Codex"
    )
    Helpers.expect.global(child, "vim.fn.maparg('<C-a>', 'x') ~= ''", true)
end

T["plugin loading"]["defines the :Nvimcodex command"] = function()
    Helpers.expect.global(child, "vim.fn.exists(':Nvimcodex')", 2)
end

T["setup()"]["sets exposed methods and default options value"] = function()
    child.lua([[require('nvimcodex').setup()]])

    -- public methods
    Helpers.expect.global_type(child, "require('nvimcodex').setup", "function")
    Helpers.expect.global_type(child, "require('nvimcodex').send", "function")
    Helpers.expect.global_type(child, "require('nvimcodex').reload_skills", "function")

    -- config
    Helpers.expect.global(child, "require('nvimcodex.config').options.debug", false)
    Helpers.expect.global_type(child, "require('nvimcodex.config').options.debug", "boolean")
end

T["setup()"]["overrides default values"] = function()
    child.lua([[require('nvimcodex').setup({
        -- write all the options with a value different than the default ones
        debug = true,
    })]])

    -- assert the value, and the type
    Helpers.expect.global(child, "require('nvimcodex.config').options.debug", true)
    Helpers.expect.global_type(child, "require('nvimcodex.config').options.debug", "boolean")
end

T["setup()"]["keymap = false removes the default mapping"] = function()
    child.lua([[require('nvimcodex').setup({ keymap = false })]])

    Helpers.expect.global(child, "vim.fn.maparg('<C-a>', 'n')", "")
    Helpers.expect.global(child, "vim.fn.maparg('<C-a>', 'x')", "")
end

T["setup()"]["keymap = '<leader>k' moves the mapping"] = function()
    child.lua([[require('nvimcodex').setup({ keymap = '<leader>k' })]])

    Helpers.expect.global(child, "vim.fn.maparg('<C-a>', 'n')", "")
    Helpers.expect.global(
        child,
        "vim.fn.maparg('<leader>k', 'n', false, true).desc",
        "Send current context to Codex"
    )
    Helpers.expect.global(child, "vim.fn.maparg('<leader>k', 'x') ~= ''", true)
end

return T

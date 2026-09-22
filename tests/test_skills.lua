local Helpers = dofile("tests/helpers.lua")

local child = Helpers.new_child_neovim()

local T = MiniTest.new_set({
    hooks = {
        pre_case = function()
            -- --noplugin: keep plugin/nvimcodex.lua's deferred skills.load()
            -- from racing the fixtures and scanning real user dirs
            child.restart({ "-u", "scripts/minimal_init.lua", "--noplugin" })
        end,
        post_once = child.stop,
    },
})

T["skills.load()"] = MiniTest.new_set()

T["skills.load()"]["scans roots, follows symlinks, descends into .system"] = function()
    child.lua([[
        local uv = vim.uv

        _G.fixture = vim.fn.tempname()
        _G.cwd = vim.fn.tempname()
        uv.fs_mkdir(_G.cwd, 493)
        uv.fs_mkdir(_G.fixture, 493)
        uv.fs_mkdir(vim.fs.joinpath(_G.fixture, "skills"), 493)

        local function write_skill(dir, content)
            uv.fs_mkdir(dir, 493)
            local fd = assert(uv.fs_open(vim.fs.joinpath(dir, "SKILL.md"), "w", 420))
            assert(uv.fs_write(fd, content, 0))
            uv.fs_close(fd)
        end

        write_skill(
            vim.fs.joinpath(_G.fixture, "skills", "a"),
            '---\nname: "alpha"\ndescription: "Alpha skill"\n---\n'
        )
        uv.fs_mkdir(vim.fs.joinpath(_G.fixture, "skills", ".system"), 493)
        write_skill(
            vim.fs.joinpath(_G.fixture, "skills", ".system", "b"),
            "---\nname: beta\ndescription: Beta skill\n---\n"
        )
        write_skill(
            vim.fs.joinpath(_G.fixture, "c-target"),
            "---\nname: gamma\n---\n"
        )
        uv.fs_symlink(
            vim.fs.joinpath(_G.fixture, "c-target"),
            vim.fs.joinpath(_G.fixture, "skills", "c-link")
        )
        uv.fs_mkdir(vim.fs.joinpath(_G.fixture, "skills", "nope"), 493)

        vim.env.CODEX_HOME = _G.fixture
        _G.home = vim.fn.tempname()
        uv.fs_mkdir(_G.home, 493)
        vim.env.HOME = _G.home -- isolate from real user skill dirs
        uv.chdir(_G.cwd)

        _G.loaded = nil
        require("nvimcodex.lib.skills").load(function(list)
            _G.loaded = list
        end)
    ]])

    child.lua([[vim.wait(2000, function() return _G.loaded ~= nil end, 10)]])
    local loaded = child.lua_get("_G.loaded")

    Helpers.expect.equality(
        vim.tbl_map(function(s)
            return s.name
        end, loaded),
        { "alpha", "beta", "gamma" }
    )
    Helpers.expect.equality(loaded[1].description, "Alpha skill")
    Helpers.expect.equality(loaded[2].description, "Beta skill")
    Helpers.expect.equality(loaded[3].description, "")
end

T["skills.load()"]["project root wins on duplicate skill names"] = function()
    child.lua([[
        local uv = vim.uv

        _G.fixture = vim.fn.tempname()
        _G.cwd = vim.fn.tempname()
        _G.home = vim.fn.tempname()
        for _, dir in ipairs({
            vim.fs.joinpath(_G.fixture, "skills", "dup"),
            vim.fs.joinpath(_G.cwd, ".codex", "skills", "dup"),
            _G.home,
        }) do
            vim.fn.mkdir(dir, "p")
        end

        local function write_skill(dir, description)
            local fd = assert(uv.fs_open(vim.fs.joinpath(dir, "SKILL.md"), "w", 420))
            assert(uv.fs_write(
                fd,
                string.format('---\nname: dup\ndescription: "%s"\n---\n', description),
                0
            ))
            uv.fs_close(fd)
        end
        write_skill(vim.fs.joinpath(_G.fixture, "skills", "dup"), "user")
        write_skill(vim.fs.joinpath(_G.cwd, ".codex", "skills", "dup"), "project")

        vim.env.CODEX_HOME = _G.fixture
        vim.env.HOME = _G.home
        uv.chdir(_G.cwd)

        _G.loaded = nil
        require("nvimcodex.lib.skills").load(function(list)
            _G.loaded = list
        end)
    ]])

    child.lua([[vim.wait(2000, function() return _G.loaded ~= nil end, 10)]])
    local loaded = child.lua_get("_G.loaded")

    Helpers.expect.equality(#loaded, 1)
    Helpers.expect.equality(loaded[1].name, "dup")
    Helpers.expect.equality(loaded[1].description, "project")
end

T["skills.load()"]["loads plugin cache skills with lowest precedence"] = function()
    child.lua([[
        local uv = vim.uv

        _G.fixture = vim.fn.tempname()
        _G.cwd = vim.fn.tempname()
        _G.home = vim.fn.tempname()
        for _, dir in ipairs({
            vim.fs.joinpath(_G.fixture, "plugins", "cache", "mk", "plug", "1.0.0", "skills", "pskill"),
            vim.fs.joinpath(_G.fixture, "plugins", "cache", "mk", "plug", "1.0.0", "skills", "dup"),
            vim.fs.joinpath(_G.fixture, "plugins", "cache", "mk", "plug", "1.0.0", "components", "x", "skills", "nope"),
            vim.fs.joinpath(_G.fixture, "skills", "dup"),
            _G.cwd,
            _G.home,
        }) do
            vim.fn.mkdir(dir, "p")
        end

        local function write_skill(dir, name, description)
            local fd = assert(uv.fs_open(vim.fs.joinpath(dir, "SKILL.md"), "w", 420))
            assert(uv.fs_write(
                fd,
                string.format('---\nname: %s\ndescription: "%s"\n---\n', name, description),
                0
            ))
            uv.fs_close(fd)
        end
        write_skill(
            vim.fs.joinpath(_G.fixture, "plugins", "cache", "mk", "plug", "1.0.0", "skills", "pskill"),
            "pskill",
            "from plugin"
        )
        write_skill(
            vim.fs.joinpath(_G.fixture, "plugins", "cache", "mk", "plug", "1.0.0", "skills", "dup"),
            "dup",
            "plugin"
        )
        write_skill(
            vim.fs.joinpath(_G.fixture, "plugins", "cache", "mk", "plug", "1.0.0", "components", "x", "skills", "nope"),
            "nope",
            "must not be loaded"
        )
        write_skill(vim.fs.joinpath(_G.fixture, "skills", "dup"), "dup", "user")

        vim.env.CODEX_HOME = _G.fixture
        vim.env.HOME = _G.home
        uv.chdir(_G.cwd)

        _G.loaded = nil
        require("nvimcodex.lib.skills").load(function(list)
            _G.loaded = list
        end)
    ]])

    child.lua([[vim.wait(2000, function() return _G.loaded ~= nil end, 10)]])
    local loaded = child.lua_get("_G.loaded")

    Helpers.expect.equality(
        vim.tbl_map(function(s)
            return s.name
        end, loaded),
        { "dup", "pskill" }
    )
    Helpers.expect.equality(loaded[1].description, "user")
    Helpers.expect.equality(loaded[2].description, "from plugin")
end

T["skills.load()"]["completes with an empty list when roots are missing"] = function()
    child.lua([[
        vim.env.CODEX_HOME = vim.fn.tempname() -- does not exist
        vim.env.HOME = vim.fn.tempname() -- does not exist
        vim.uv.chdir(vim.fn.tempname())
        _G.loaded = nil
        require("nvimcodex.lib.skills").load(function(list)
            _G.loaded = list
        end)
    ]])

    child.lua([[vim.wait(2000, function() return _G.loaded ~= nil end, 10)]])
    local loaded = child.lua_get("_G.loaded")

    Helpers.expect.equality(loaded, {})
end

return T

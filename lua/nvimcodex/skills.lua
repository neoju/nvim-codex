local skills = {}

local cache = {}
local loading = false
local loaded = false
local pending_callbacks = {}

--- Ordered skill roots, project-local first so project skills shadow user ones
--- on name collisions (first occurrence of a name wins).
function skills.dirs()
    local uv = vim.uv
    local cwd = uv.cwd()
    local home = uv.os_homedir()
    local codex_home = vim.env.CODEX_HOME or vim.fs.joinpath(home, ".codex")

    return {
        { path = vim.fs.joinpath(cwd, ".codex", "skills"), kind = "skills" },
        { path = vim.fs.joinpath(cwd, ".agents", "skills"), kind = "skills" },
        { path = vim.fs.joinpath(codex_home, "skills"), kind = "skills" },
        { path = vim.fs.joinpath(home, ".agents", "skills"), kind = "skills" },
        { path = vim.fs.joinpath(codex_home, "plugins", "cache"), kind = "plugins" },
    }
end

local function unquote(value)
    if value == nil then
        return nil
    end
    value = vim.trim(value)
    local first = value:sub(1, 1)
    local last = value:sub(-1)
    if #value >= 2 and first == last and (first == '"' or first == "'") then
        return value:sub(2, -2)
    end
    return value
end

--- Parses `name:` and `description:` from the YAML frontmatter delimited by
--- the first `---` line and the next `---` line.
local function parse_frontmatter(content)
    local fields = {}
    local in_frontmatter = false
    for line in content:gmatch("[^\r\n]+") do
        if line:match("^%-%-%-%s*$") then
            if in_frontmatter then
                break
            end
            in_frontmatter = true
        elseif in_frontmatter then
            local key, value = line:match("^(%w+)%s*:%s*(.-)%s*$")
            if key == "name" or key == "description" then
                fields[key] = unquote(value)
            end
        end
    end
    return fields
end

--- Scans all roots on the next event-loop turn and fills the cache. Results are
--- collected per root and merged in `dirs()` order, so root precedence is
--- deterministic.
function skills.load(callback)
    if callback then
        table.insert(pending_callbacks, callback)
    end
    if loading then
        return
    end
    loading = true

    local uv = vim.uv
    local roots = skills.dirs()
    local function finalize(results)
        local out = {}
        local seen = {}
        for index = 1, #roots do
            for _, record in ipairs(results[index] or {}) do
                if not seen[record.name] then
                    seen[record.name] = true
                    table.insert(out, record)
                end
            end
        end
        table.sort(out, function(a, b)
            return a.name < b.name
        end)
        cache = out
        loading = false
        loaded = true
        local callbacks = pending_callbacks
        pending_callbacks = {}
        for _, cb in ipairs(callbacks) do
            cb(cache)
        end
    end

    --- Reads `dir/SKILL.md` and appends a record to `out`.
    local function read_skill(dir_path, dir_name, root, out)
        local skill_md = vim.fs.joinpath(dir_path, "SKILL.md")
        if not uv.fs_stat(skill_md) then
            return
        end
        local ok, lines = pcall(vim.fn.readfile, skill_md)
        if not ok then
            return
        end
        local fields = parse_frontmatter(table.concat(lines, "\n"))
        table.insert(out, {
            name = fields.name or dir_name,
            description = fields.description or "",
            path = skill_md,
            root = root,
        })
    end

    --- Scans one directory level; each child dir is either a skill (has
    --- SKILL.md) or, when named `.system`, scanned one level deeper.
    local function scan_dir(dir, root, out, is_system)
        local handle = uv.fs_scandir(dir)
        if not handle then
            return
        end
        local entry = uv.fs_scandir_next(handle)
        while entry do
            local path = vim.fs.joinpath(dir, entry)
            -- fs_stat follows symlinks, so linked skill dirs work.
            local stat = uv.fs_stat(path)
            if stat and stat.type == "directory" then
                if entry == ".system" and not is_system then
                    scan_dir(path, path, out, true)
                else
                    read_skill(path, entry, root, out)
                end
            end
            entry = uv.fs_scandir_next(handle)
        end
    end

    --- Scans a Codex plugins cache: plugin skills live exactly three directory
    --- levels deep (<marketplace>/<plugin>/<version>/skills/<name>/SKILL.md).
    --- Anything else (e.g. components/) is ignored.
    local function scan_plugins_cache(dir, out)
        local function each_dir(parent, fn)
            local handle = uv.fs_scandir(parent)
            if not handle then
                return
            end
            local entry = uv.fs_scandir_next(handle)
            while entry do
                local path = vim.fs.joinpath(parent, entry)
                local stat = uv.fs_stat(path) -- follows symlinks
                if stat and stat.type == "directory" then
                    fn(path)
                end
                entry = uv.fs_scandir_next(handle)
            end
        end
        each_dir(dir, function(marketplace)
            each_dir(marketplace, function(plugin)
                each_dir(plugin, function(version)
                    local skills_dir = vim.fs.joinpath(version, "skills")
                    if uv.fs_stat(skills_dir) then
                        scan_dir(skills_dir, skills_dir, out, true)
                    end
                end)
            end)
        end)
    end

    vim.schedule(function()
        local results = {}
        for index, root in ipairs(roots) do
            results[index] = {}
            if root.kind == "plugins" then
                scan_plugins_cache(root.path, results[index])
            else
                scan_dir(root.path, root.path, results[index], false)
            end
        end
        finalize(results)
    end)
end

function skills.get()
    return cache
end

--- Clears the cache so the next `ensure_loaded` rescans; does not scan itself.
function skills.invalidate()
    cache = {}
    loaded = false
end

--- Calls `callback` with the cache immediately when already loaded, otherwise
--- kicks off a scan first. Used to load skills lazily on first prompt open.
function skills.ensure_loaded(callback)
    if loaded then
        if callback then
            callback(cache)
        end
        return
    end
    skills.load(callback)
end

function skills.reload(callback)
    cache = {}
    skills.load(callback)
end

return skills

local log = require("nvimcodex.log")

local commands = { list = {}, modifiers = {} }
local attributes = { "goal", "context", "output", "boundaries" }
local modifier_fields = {
    description = true,
    des = true,
    requires_context = true,
    primary_goal = true,
    primary_context = true,
    primary_output = true,
    primary_boundaries = true,
}

local function load_definition(path, kind)
    local lines = vim.fn.readfile(path)
    assert(lines[1] == "---", "Missing command header: " .. path)

    local command = {}
    local line_number = 2
    while lines[line_number] and lines[line_number] ~= "---" do
        local key, value = lines[line_number]:match("^([%w_]+):%s*(.+)$")
        assert(key, "Invalid command header: " .. path .. ":" .. line_number)
        command[key] = vim.json.decode(value)
        if kind == "modifiers" then
            assert(modifier_fields[key], "Invalid modifier attribute: " .. key .. " in " .. path)
        end
        line_number = line_number + 1
    end
    assert(lines[line_number] == "---", "Unclosed command header: " .. path)

    if line_number < #lines then
        assert(kind == "commands", "Modifiers cannot have special instructions: " .. path)
        command.special_instruction = table.concat(lines, "\n", line_number + 1)
    end
    command.description = command.description or command.des
    return command
end

for kind, definitions in pairs({ commands = commands.list, modifiers = commands.modifiers }) do
    local paths = "lua/nvimcodex/prompt/definitions/" .. kind .. "/*.md"
    for _, path in ipairs(vim.api.nvim_get_runtime_file(paths, true)) do
        definitions[vim.fn.fnamemodify(path, ":t:r")] = load_definition(path, kind)
    end
end

function commands.apply(ctx, text)
    local tasks = {}
    local pending = { definitions = {}, skills = {} }
    local current
    text = text:gsub("[@#$][%w_:%-]+", function(token)
        local prefix, name = token:sub(1, 1), token:sub(2)
        if prefix == "$" then
            table.insert((current or pending).skills, token)
            return ""
        end
        local definitions = prefix == "@" and commands.list or commands.modifiers
        if not definitions[name] then
            return token
        end
        if prefix == "@" then
            current =
                { name = name, definitions = { { name = name, prefix = prefix } }, skills = {} }
            if #tasks == 0 then
                vim.list_extend(current.definitions, pending.definitions)
                current.skills = pending.skills
            end
            table.insert(tasks, current)
        else
            table.insert((current or pending).definitions, { name = name, prefix = prefix })
        end
        return ""
    end)
    local value = vim.trim(text:gsub("%s%s+", " "))

    if #tasks == 0 then
        tasks[1] = pending
    end

    local result = {}
    for _, entry in ipairs(tasks) do
        local task = {
            name = entry.name,
            value = value,
            location = ctx.location or "",
            files = ctx.files and vim.list_extend({}, ctx.files) or nil,
            skills = entry.skills,
        }
        for _, definition in ipairs(entry.definitions) do
            local definitions = definition.prefix == "@" and commands.list or commands.modifiers
            local command = definitions[definition.name]
            if command.requires_value and value == "" then
                log.notify(
                    "commands",
                    vim.log.levels.ERROR,
                    true,
                    definition.prefix .. definition.name .. " requires a question"
                )
                return nil
            end
            if command.clear_location then
                task.location = ""
            elseif command.location then
                task.location = ctx[command.location] or ""
            end
            if
                command.requires_context
                and task.location == ""
                and (not task.files or #task.files == 0)
            then
                log.notify(
                    "commands",
                    vim.log.levels.ERROR,
                    true,
                    definition.prefix .. definition.name .. " requires selected context"
                )
                return nil
            end
            if command.clear_value then
                task.value = ""
            end
            for _, attribute in ipairs(attributes) do
                local field = "primary_" .. attribute
                if command[field] then
                    task.attributes = task.attributes or {}
                    task.attributes[attribute] = command[field]
                end
            end
            if command.special_instruction then
                task.special_instruction = command.special_instruction
            end
        end
        table.insert(result, task)
    end
    return result
end

return commands

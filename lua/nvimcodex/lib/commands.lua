local commands = {}
local fs = require("nvimcodex.lib.fs")

commands.list = {
    buffer = {
        description = "Target the whole current file (relative path, no line range)",
        apply = function(ctx)
            ctx.location = ctx.filepath
        end,
    },
    ask = {
        description = "Answer a request without editing files",
        apply = function(ctx)
            ctx.prefix = table.concat({
                "Goal: Answer the request below.",
                "Constraint: Do not modify files.",
            }, "\n")

            ctx.value = string.format("Question: %s", ctx.value)
        end,
    },
    explain = {
        description = "Explain selected code and its surrounding context",
        apply = function(ctx)
            ctx.prefix = table.concat({
                "Goal: Explain the selected code and the surrounding implementation needed to understand it.",
                "Include: its purpose, control flow, relevant callers or dependencies, and effects.",
                "Constraint: Do not modify files.",
            }, "\n")

            ctx.value = ""
        end,
    },
}

--- Rewrites `ctx` for each known `@name` token in `text`, strips those tokens,
--- and returns `ctx, cleaned_text`. Unknown `@foo` tokens are left untouched.
function commands.apply(ctx, text)
    ctx.value = text
    for name in ctx.value:gmatch("@(%w+)") do
        local command = commands.list[name]

        if command then
            command.apply(ctx)
            ctx.value = ctx.value:gsub("@" .. name .. "%f[%W]", "", 1)
        end
    end

    ctx.value = ctx.value:gsub("%s%s+", " ")
    ctx.value = vim.trim(ctx.value)

    return ctx
end

function commands.format(ctx)
    local lines = {}

    if ctx.location ~= "" then
        if string.match(ctx.location, "neo%-tree filesystem") then
            ctx.location = "\n" .. table.concat(fs.get_neotree_context(), "\n")
        end

        table.insert(lines, string.format("Context: %s", ctx.location))
    end

    if ctx.prefix then
        table.insert(lines, ctx.prefix)
    end

    if ctx.value ~= "" then
        table.insert(lines, ctx.value)
    end

    if ctx.subfix then
        table.insert(lines, ctx.subfix)
    end

    return table.concat(lines, "\n")
end

return commands

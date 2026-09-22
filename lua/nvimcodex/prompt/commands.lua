local log = require("nvimcodex.log")

local commands = {}

commands.list = {
    buffer = {
        description = "Target the whole current file (relative path, no line range)",
        apply = function(ctx)
            ctx.location = ctx.filepath
        end,
    },
    ask = {
        description = "Answer a request without editing files",
        requires_value = true,
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
    scoped = {
        description = "Restrict edits to the provided context",
        requires_context = true,
        apply = function(ctx)
            ctx.prefix = "Constraint: Only edit the code within the provided context. "
                .. "Do not modify any code or files outside that context."
        end,
    },
}

--- Rewrites `ctx` for each known `@name` token in `text`, strips those tokens,
--- and returns `ctx, cleaned_text`. Unknown `@foo` tokens are left untouched.
function commands.apply(ctx, text)
    ctx.value = text
    local requires_value = false

    for name in ctx.value:gmatch("@([%w-]+)") do
        local command = commands.list[name]

        if command then
            if
                command.requires_context
                and ctx.location == ""
                and (not ctx.files or #ctx.files == 0)
            then
                log.notify(
                    "commands",
                    vim.log.levels.ERROR,
                    true,
                    "@" .. name .. " requires selected context"
                )
                return nil
            end
            requires_value = requires_value or command.requires_value
            command.apply(ctx)
            ctx.value = ctx.value:gsub("@" .. name .. "%f[%W]", "", 1)
        end
    end

    ctx.value = ctx.value:gsub("%s%s+", " ")
    ctx.value = vim.trim(ctx.value)

    if requires_value and ctx.value == "Question:" then
        log.notify("commands", vim.log.levels.ERROR, true, "@ask requires a question")
        return nil
    end

    return ctx
end

return commands

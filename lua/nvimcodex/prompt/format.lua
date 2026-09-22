local M = {}

--- Renders a prompt context into the text sent to Codex. Pure function.
function M.render(ctx)
    local lines = {}

    if ctx.files and #ctx.files > 0 then
        local files_lines = { "Context: " }
        for _, path in ipairs(ctx.files) do
            table.insert(files_lines, "  - " .. path)
        end
        table.insert(lines, table.concat(files_lines, "\n"))
    elseif ctx.location ~= "" then
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

return M

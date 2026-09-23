local M = {}

local separate_tasks_guidance = "\z
    Treat these as separate tasks. Run non-conflicting tasks in parallel; \z
    run conflicting tasks sequentially. For concurrent edits, consider separate worktrees."

--- Renders tasks into the text sent to Codex. Pure function.
function M.render(tasks)
    local only_task = tasks[1]
    if
        #tasks == 1
        and next(only_task.attributes) == nil
        and not only_task.special_instruction
        and #only_task.skills == 0
        and #only_task.files == 0
        and only_task.location == ""
    then
        return only_task.value
    end

    local lines = {}
    if #tasks > 1 then
        table.insert(lines, "<INSTRUCTIONS>")
        table.insert(lines, separate_tasks_guidance)
        table.insert(lines, "</INSTRUCTIONS>")
        table.insert(lines, "")
    end

    for index, task in ipairs(tasks) do
        if index > 1 then
            table.insert(lines, "---------------------------------------------")
        end

        table.insert(lines, "<INSTRUCTIONS>")

        if task.special_instruction then
            table.insert(lines, "General: " .. task.special_instruction:gsub("\n", "\n  "))
        end

        for _, attribute in ipairs({ "goal", "output", "boundaries" }) do
            local content = task.attributes[attribute]
            if content then
                local label = attribute:sub(1, 1):upper() .. attribute:sub(2)

                table.insert(lines, label .. ": " .. content)
            end
        end

        local files = task.files
        if #files == 0 and task.location ~= "" then
            files = { task.location }
        end

        for i, path in ipairs(files) do
            if i == 1 then
                table.insert(lines, "Context:")
            end

            table.insert(lines, "- " .. path)
        end

        for i, skill in ipairs(task.skills) do
            if i == 1 then
                table.insert(lines, "Skills:")
            end

            table.insert(lines, "- " .. skill)
        end

        table.insert(lines, "</INSTRUCTIONS>")

        if task.value ~= "" then
            table.insert(lines, "")
            table.insert(lines, "<USER_PROMPT>")
            table.insert(lines, task.value)
            table.insert(lines, "</USER_PROMPT>")
        end
    end

    return table.concat(lines, "\n")
end

return M

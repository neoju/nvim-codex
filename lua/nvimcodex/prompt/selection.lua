local M = {}

function M.get_line_range()
    local start_line, end_line
    if vim.fn.mode():match("^[vV\022]") then
        -- `'<`/`'>` marks are only set after leaving visual mode
        start_line = vim.fn.line("v")
        end_line = vim.fn.line(".")
    else
        start_line = vim.fn.line("'<")
        end_line = vim.fn.line("'>")
    end

    if start_line > end_line then
        start_line, end_line = end_line, start_line
    end

    return start_line, end_line
end

return M

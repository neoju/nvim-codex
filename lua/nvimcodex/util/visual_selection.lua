local M = {}

function M.get_line_range()
    local start_line = vim.fn.line("'<")
    local end_line = vim.fn.line("'>")

    if start_line > end_line then
        start_line, end_line = end_line, start_line
    end

    return start_line, end_line
end

return M

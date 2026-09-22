local selection = require("nvimcodex.prompt.selection")

local M = {}

--- Returns the relative paths of the Neo-tree nodes under the visual
--- selection, or under the cursor line when not in visual mode. Returns an
--- empty list when neo-tree is not available.
function M.selected_paths()
    local ok, manager = pcall(require, "neo-tree.sources.manager")
    if not ok then
        return {}
    end
    local state = manager.get_state("filesystem")

    local in_visual = vim.fn.mode():match("^[vV\022]") ~= nil
    local start_line, end_line
    if in_visual then
        vim.cmd("normal! \27")
        start_line, end_line = selection.get_line_range()
    else
        start_line = vim.fn.line(".")
        end_line = start_line
    end

    local paths = {}
    for line = start_line, end_line do
        local node = state.tree:get_node(line)
        if node and node.path then
            table.insert(paths, vim.fn.fnamemodify(node.path, ":~:."))
        end
    end

    return paths
end

return M

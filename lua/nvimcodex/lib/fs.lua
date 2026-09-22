local visual_selection = require("nvimcodex.util.visual_selection")

local fs = {}

function fs.get_neotree_context()
    local manager = require("neo-tree.sources.manager")
    local state = manager.get_state("filesystem")

    vim.cmd("normal! \27")

    local start_line, end_line = visual_selection.get_line_range()
    local paths = {}

    for line = start_line, end_line do
        local node = state.tree:get_node(line)
        if node and node.path then
            table.insert(paths, "  - " .. vim.fn.fnamemodify(node.path, ":~:."))
        end
    end

    return paths
end

return fs

local log = require("nvimcodex.log")
local selection = require("nvimcodex.prompt.selection")
local commands = require("nvimcodex.prompt.commands")
local format = require("nvimcodex.prompt.format")
local input = require("nvimcodex.ui.input")
local tmux = require("nvimcodex.transport.tmux")
local neotree = require("nvimcodex.integrations.neotree")

local M = {}

--- Captures the current context: relative file path plus a visual line range,
--- or the selected Neo-tree paths when the current buffer is a neo-tree one.
function M.capture()
    local ctx = { filepath = vim.fn.expand("%:."), location = "" }
    local in_visual = vim.fn.mode():match("^[vV\022]") ~= nil

    if vim.bo.filetype == "neo-tree" then
        ctx.files = neotree.selected_paths()
        ctx.filepath, ctx.location = "", ""
        return ctx
    end

    if in_visual then
        local start_line, end_line = selection.get_line_range()
        if start_line ~= end_line then
            ctx.location = string.format("%s:L%d-L%d", ctx.filepath, start_line, end_line)
        else
            ctx.location = string.format("%s:L%d", ctx.filepath, start_line)
        end
    end

    return ctx
end

--- Captures the context, asks the user for input, then formats and sends the
--- resulting prompt to the Codex tmux pane.
function M.send()
    local ctx = M.capture()

    input.open({
        prompt = "Ask Codex: ",
        win = {
            relative = "cursor",
            row = 1,
            col = 0,
        },
    }, function(value)
        if value == nil then
            return -- User cancelled
        end

        ctx = commands.apply(ctx, value)
        local text = format.render(ctx)

        local sent, error_message = tmux.send(text, vim.fn.getcwd())
        if not sent then
            log.notify("send", vim.log.levels.WARN, true, "%s", error_message)
        end
    end)
end

return M

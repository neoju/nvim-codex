local skills = require("nvimcodex.skills")
local commands = require("nvimcodex.prompt.commands")

local source = {}

function source.new()
    return setmetatable({}, { __index = source })
end

function source.enabled()
    return vim.bo.filetype == "nvimcodex_ask"
end

function source.get_trigger_characters()
    return { "$", "@" }
end

local function completion_item_kind()
    local ok, types = pcall(require, "blink.cmp.types")
    if ok and types and types.CompletionItemKind then
        return types.CompletionItemKind
    end
    return vim.lsp.protocol.CompletionItemKind
end

local function trigger_char(ctx)
    local col = ctx.bounds and ctx.bounds.start_col or 1
    return (ctx.line or ""):sub(col - 1, col - 1)
end

--- Descriptions are rendered inline (blink's `label_description` column, which
--- truncates on its own) instead of a documentation popup, so the menu stays
--- stable while typing.
local function label_details(description)
    local first_line = vim.trim((description or ""):match("^[^\r\n]*"))
    return { description = first_line }
end

local function skill_items()
    local kind = completion_item_kind()
    local items = {}
    for _, skill in ipairs(skills.get()) do
        local text = "$" .. skill.name
        table.insert(items, {
            label = text,
            insertText = text,
            filterText = text,
            kind = kind.Function,
            labelDetails = label_details(skill.description),
        })
    end
    return items
end

local function command_items()
    local kind = completion_item_kind()
    local items = {}
    for name, command in pairs(commands.list) do
        local text = "@" .. name
        table.insert(items, {
            label = text,
            insertText = text,
            filterText = text,
            kind = kind.Keyword,
            labelDetails = label_details(command.description),
        })
    end
    table.sort(items, function(a, b)
        return a.label < b.label
    end)
    return items
end

function source.get_completions(_, ctx, callback)
    local items
    local char = trigger_char(ctx)
    if char == "$" then
        items = skill_items()
    elseif char == "@" then
        items = command_items()
    else
        items = {}
    end

    callback({
        is_incomplete_forward = false,
        is_incomplete_backward = false,
        items = vim.tbl_map(function(item)
            item.insertTextFormat = vim.lsp.protocol.InsertTextFormat.PlainText
            return item
        end, items),
    })
end

function source.reload()
    skills.reload()
end

return source

local config = require("nvimcodex.config")

local tmux = {}

local function normalize_path(path)
    return vim.fn.resolve(vim.fn.fnamemodify(path, ":p"))
end

local function focus_codex_pane(pane_id)
    local response = vim.system({
        "tmux",
        "select-pane",
        "-t",
        pane_id,
    }):wait()

    if response.code ~= 0 then
        vim.notify(response.stderr, vim.log.levels.WARN)
    end
end

local function send_enter(pane_id)
    local response = vim.system({
        "tmux",
        "send-keys",
        "-t",
        pane_id,
        "Enter",
    }):wait()

    if response.code ~= 0 then
        vim.notify(response.stderr, vim.log.levels.WARN)
    end
end

function tmux.is_available()
    return vim.fn.executable("tmux") == 1
end

function tmux.find_codex_pane(path)
    local result = vim.system({
        "tmux",
        "list-panes",
        "-F",
        "#{pane_id}\t#{pane_current_command}\t#{pane_current_path}",
    }, { text = true }):wait()

    if result.code ~= 0 then
        return nil, result.stderr
    end

    local current_path = normalize_path(path or vim.fn.getcwd())
    for pane in result.stdout:gmatch("[^\n]+") do
        local pane_id, command, pane_path = pane:match("^(.-)\t(.-)\t(.*)$")

        if command == "codex" and normalize_path(pane_path) == current_path then
            return pane_id
        end
    end

    return nil, "No tmux pane running codex was found in the current path"
end

function tmux.send_to_codex(text, path)
    local pane_id, error_message = tmux.find_codex_pane(path)
    if pane_id == nil then
        return false, error_message
    end

    local send_result = vim.system({
        "tmux",
        "send-keys",
        "-t",
        pane_id,
        "-l",
        text,
    }):wait()

    if send_result.code ~= 0 then
        return false, send_result.stderr
    end

    if config.options.auto_focus_codex then
        focus_codex_pane(pane_id)
    end

    -- Keep this at bottom + defer timeout to ensure it not overlap with other tmux command
    -- If no defer_fn sometime it will just send a `\n` char instead of Enter press
    -- Idk if 50ms is safe across machine, who know? :D
    if config.options.auto_send then
        vim.defer_fn(function()
            send_enter(pane_id)
        end, 50)
    end

    return true
end

return tmux

local tmux = {}

local function normalize_path(path)
    return vim.fn.resolve(vim.fn.fnamemodify(path, ":p"))
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

    local select_result = vim.system({
        "tmux",
        "select-pane",
        "-t",
        pane_id,
    }):wait()

    if select_result.code ~= 0 then
        return false, select_result.stderr
    end

    return true
end

return tmux

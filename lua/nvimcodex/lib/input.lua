local input = {}

function input.open(opts, on_confirm)
    local ok, snacks = pcall(require, "snacks")
    if not ok then
        vim.notify("[nvimcodex.nvim] snacks.nvim is required for input", vim.log.levels.ERROR)
        return
    end

    snacks.input(opts, on_confirm)
end

return input

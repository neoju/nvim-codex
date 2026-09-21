local input = {}

function input.open(opts, on_confirm)
    local snacks_ok, snacks = pcall(require, "snacks")

    if snacks_ok then
        local input_ok, snacks_input = pcall(function()
            return snacks.input
        end)

        if input_ok and snacks_input ~= nil then
            snacks_input(opts, on_confirm)
            return
        end
    end

    vim.ui.input(opts, on_confirm)
end

return input

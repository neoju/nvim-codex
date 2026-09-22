-- You can use this loaded variable to enable conditional parts of your plugin.
if _G.NvimcodexLoaded then
    return
end

_G.NvimcodexLoaded = true

vim.api.nvim_create_user_command("Nvimcodex", function()
    require("nvimcodex").send()
end, {})

require("nvimcodex.keymap").apply()

vim.api.nvim_create_autocmd("DirChanged", {
    group = vim.api.nvim_create_augroup("Nvimcodex", { clear = true }),
    callback = function()
        require("nvimcodex.skills").invalidate()
    end,
})

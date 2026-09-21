-- You can use this loaded variable to enable conditional parts of your plugin.
if _G.NvimcodexLoaded then
    return
end

_G.NvimcodexLoaded = true

require("nvimcodex")

vim.api.nvim_create_user_command("Nvimcodex", function()
    require("nvimcodex").toggle()
end, {})

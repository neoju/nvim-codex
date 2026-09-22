-- You can use this loaded variable to enable conditional parts of your plugin.
if _G.NvimcodexLoaded then
    return
end

_G.NvimcodexLoaded = true

vim.api.nvim_create_user_command("Nvimcodex", function()
    require("nvimcodex").toggle()
end, {})

vim.keymap.set({ "n", "x" }, "<C-a>", function()
    require("nvimcodex").send_to_codex()
end, {
    desc = "Send current context to Codex",
})

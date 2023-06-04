local PopUp = require("stormcaller.lib.ui.PopUp")
local tcm = require("stormcaller.api.tailwind_class_modifier")

local M = {}

local colors = {
    { text = "", keymaps = { "0" }, hidden = true },
    { text = "slate", keymaps = { "sl" } },
    { text = "gray", keymaps = { "G" } },
    { text = "zinc", keymaps = { "z" } },
    { text = "neutral", keymaps = { "n" } },
    { text = "stone", keymaps = { "st" } },
    { text = "red", keymaps = { "r" } },
    { text = "orange", keymaps = { "o" } },
    { text = "amber", keymaps = { "a" } },
    { text = "yellow", keymaps = { "y" } },
    { text = "lime", keymaps = { "l" } },
    { text = "green", keymaps = { "g" } },
    { text = "emerald", keymaps = { "e" } },
    { text = "teal", keymaps = { "t" } },
    { text = "cyan", keymaps = { "c" } },
    { text = "sky", keymaps = { "sk" } },
    { text = "blue", keymaps = { "b" } },
    { text = "indigo", keymaps = { "i" } },
    { text = "violet", keymaps = { "v" } },
    { text = "purple", keymaps = { "p" } },
    { text = "fuchsia", keymaps = { "f" } },
    { text = "pink", keymaps = { "P" } },
    { text = "rose", keymaps = { "R" } },
    { text = "white", keymaps = { "w" }, single = true },
    { text = "black", keymaps = { "B" }, single = true },
}

local steps = {
    { text = "100", keymaps = { "m", "1", "q" } },
    { text = "200", keymaps = { ",", "2", "w" } },
    { text = "300", keymaps = { ".", "3", "e" } },
    { text = "400", keymaps = { "j", "4", "r" } },
    { text = "500", keymaps = { "k", "5", "a" } },
    { text = "600", keymaps = { "l", "6", "s" } },
    { text = "700", keymaps = { "u", "7", "d" } },
    { text = "800", keymaps = { "i", "8", "f" } },
    { text = "900", keymaps = { "o", "9", "g" } },
}

local color_class_picker_menu = function(filetype, prefix, fn)
    local popup = PopUp:new({
        filetype = filetype,
        steps = {
            {
                items = colors,
                format_fn = function(_, current_item)
                    return string.format("%s-%s", prefix, current_item.text)
                end,
            },
            {
                items = steps,
                format_fn = function(results, current_item)
                    return string.format("%s-%s-%s", prefix, results[1], current_item.text)
                end,
                callback = function(results)
                    local value = string.format("%s-%s-%s", prefix, results[1], results[2])
                    fn({ value = value })
                end,
            },
        },
    })

    popup:show()
end

M.change_text_color = function()
    color_class_picker_menu("tailwind-text-color-picker", "text", tcm.change_text_color)
end
M.change_background_color = function()
    color_class_picker_menu("tailwind-bg-color-picker", "bg", tcm.change_background_color)
end

return M

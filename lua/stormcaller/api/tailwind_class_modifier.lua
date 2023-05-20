local M = {}

local catalyst = require("stormcaller.lib.catalyst")
local lib_ts = require("stormcaller.lib.tree-sitter")
local lib_ts_tsx = require("stormcaller.lib.tree-sitter.tsx")

---@param buf number
---@param node TSNode
local function set_empty_className_property(buf, node)
    local tag_node = lib_ts_tsx.get_tag_identifier_node(node)
    if not tag_node then error("Given node argument shouldn't have been nil") end

    local start_row, _, _, end_col = tag_node:range()
    vim.api.nvim_buf_set_text(buf, start_row, end_col, start_row, end_col, { ' className=""' })
end

---@param class_names string[]
---@return string[]
local function remove_empty_strings(class_names)
    for i = #class_names, 1, -1 do
        if class_names[i] == "" then table.remove(class_names, i) end
    end
    return class_names
end

---@param class_names string[]
---@return string
local function format_class_names(class_names)
    class_names = remove_empty_strings(class_names)
    local str = table.concat(class_names, " ")
    return string.format('"%s"', str)
end

---@param class_names string[]
---@param modify_to string
---@return string
local function append_new_class_name(class_names, modify_to)
    table.insert(class_names, modify_to)

    return format_class_names(class_names)
end

---@class modify_padding_Opts
---@field axis "omni" | "x" | "y" | "l" | "r" | "t" | "b"
---@field modify_to string

M.change_padding = function(o)
    if not catalyst.is_active() then return end

    if not lib_ts_tsx.get_className_property_string_node(catalyst.buf(), catalyst.node()) then
        set_empty_className_property(catalyst.buf(), catalyst.node())
    end

    local class_names, className_string_node =
        lib_ts_tsx.extract_class_names(catalyst.buf(), catalyst.node())

    local class_names_replacement = append_new_class_name(class_names, o.modify_to)

    lib_ts.replace_node_text({
        node = className_string_node,
        buf = catalyst.buf(),
        replacement = class_names_replacement,
    })

    catalyst.refresh_node()
end

return M

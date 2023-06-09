local selection = require("deliberate.lib.selection")
local aggregator = require("deliberate.lib.tree-sitter.language_aggregator")
local catalyst = require("deliberate.lib.catalyst")
local lib_ts = require("deliberate.lib.tree-sitter")

local M = {}

local has_been_requested_recently = false

M.has_been_requested_recently = function() return has_been_requested_recently end
M.finish_request = function() has_been_requested_recently = false end

---@param buf number
---@param node TSNode
local function find_or_create_attribute_value_node(buf, node, attribute, content)
    local attribute_value_node = aggregator.get_attribute_value(buf, node, attribute)
    if attribute_value_node then return attribute_value_node end

    local tag_node = aggregator.get_tag_identifier_node(node)
    if not tag_node then error("Given node argument shouldn't have been nil") end

    local start_row, _, _, end_col = tag_node:range()
    local formatted_content = string.format(" %s=%s", attribute, content)
    vim.api.nvim_buf_set_text(buf, start_row, end_col, start_row, end_col, { formatted_content })

    selection.refresh_tree()
end

M.jump_to_attribute_value_node = function(attribute)
    local attribute_value_node =
        aggregator.get_attribute_value(catalyst.buf(), catalyst.node(), attribute)
    if not attribute_value_node then return end
    local _, _, end_row, end_col = attribute_value_node:range()
    vim.api.nvim_win_set_cursor(catalyst.win(), { end_row + 1, end_col - 1 })
end

---@class Attribute_Changer_Opts
---@field attribute string
---@field content string

---@param o Attribute_Changer_Opts
M.change = function(o)
    selection.archive_for_undo()
    require("deliberate.api.dot_repeater").register(M.change, o)

    has_been_requested_recently = true

    local attribute_value_node =
        find_or_create_attribute_value_node(catalyst.buf(), catalyst.node(), o.attribute, o.content)

    if not attribute_value_node then return end

    lib_ts.replace_node_text({
        node = attribute_value_node,
        buf = catalyst.buf(),
        replacement = { o.content },
    })

    selection.refresh_tree()
end

return M

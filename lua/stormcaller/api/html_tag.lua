local M = {}

local catalyst = require("stormcaller.lib.catalyst")
local navigator = require("stormcaller.lib.navigator")
local lib_ts = require("stormcaller.lib.tree-sitter")
local lib_ts_tsx = require("stormcaller.lib.tree-sitter.tsx")

---@param buf number
---@param node TSNode
---@return string
local find_indents = function(buf, node)
    local start_row = node:range()
    local first_line = vim.api.nvim_buf_get_lines(buf, start_row, start_row + 1, false)[1]
    return string.match(first_line, "^%s+")
end

---@param index number
---@param end_row number
---@param start_col number
local function update_selected_node(index, end_row, start_col)
    local root = lib_ts.get_root({ parser_name = "tsx", buf = catalyst.buf(), reset = true })
    local updated_node =
        root:named_descendant_for_range(end_row + 1, start_col, end_row + 1, start_col)
    updated_node = lib_ts_tsx.get_jsx_node(updated_node)
    catalyst.update_node_in_selection(index, updated_node)
end

---@class tag_add_Opts
---@field tag string
---@field destination "next" | "previous" | "inside"
---@field content string

---@param index number
---@param content string
---@param indents string
---@return number, number
local function handle_inside_destination(index, content, indents)
    local first_closing_bracket = lib_ts.capture_nodes_with_queries({
        root = catalyst.selected_nodes()[index],
        buf = catalyst.buf(),
        parser_name = "tsx",
        queries = { [[ (">" @closing_bracket) ]] },
        capture_groups = { "closing_bracket" },
    })[1]

    local _, _, b_row, b_col = first_closing_bracket:range()
    content = string.rep(" ", vim.bo.tabstop) .. content

    vim.api.nvim_buf_set_text(catalyst.buf(), b_row, b_col, b_row, b_col, { "", content, indents })

    -- we do this because `nvim_buf_set_text()` moves the cursor down
    -- if cursor row is equal or below where we start changing buffer text.
    if catalyst.selection_index_matches_catalyst(index) then catalyst.move_to() end

    local update_row = b_row
    local update_col = b_col + vim.bo.tabstop
    return update_row, update_col
end

---@param destination string
---@param content string
---@param og_end_row number
---@param og_start_col number
---@return number, number
local function handle_next_or_previous_destination(destination, content, og_end_row, og_start_col)
    local offset = destination == "previous" and 0 or 1
    local target_row = og_end_row + offset

    vim.api.nvim_buf_set_lines(catalyst.buf(), target_row, target_row, false, { content })

    local update_row = target_row - 1
    local update_col = og_start_col
    return update_row, update_col
end

---@param o tag_add_Opts
M.add = function(o)
    for i = 1, #catalyst.selected_nodes() do
        local update_row, update_col

        local og_node = catalyst.selected_nodes()[i]
        local _, og_start_col, og_end_row = og_node:range()

        local placeholder = o.content or "###"
        local indents = find_indents(catalyst.buf(), og_node)
        local content = string.format("%s<%s>%s</%s>", indents, o.tag, placeholder, o.tag)

        if o.destination == "inside" then
            update_row, update_col = handle_inside_destination(i, content, indents)
        else
            update_row, update_col = handle_next_or_previous_destination(
                o.destination,
                content,
                og_end_row,
                og_start_col
            )
        end

        catalyst.refresh_tree()
        update_selected_node(i, update_row, update_col)
    end

    if #catalyst.selected_nodes() == 1 then
        navigator.move({ destination = o.destination == "previous" and "previous" or "next" })
    end
end

return M

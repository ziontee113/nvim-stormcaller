local lib_ts = require("deliberate.lib.tree-sitter")
local aggregator = require("deliberate.lib.tree-sitter.language_aggregator")
local catalyst = require("deliberate.lib.catalyst")

local M = {}

---@class navigator_move_Args
---@field destination "next-sibling" | "previous-sibling" | "next" | "previous" | "parent"
---@field select_move boolean

---@param nodes TSNode[]
---@param row number
---@return TSNode
local function find_closest_next_node_to_row(nodes, row)
    local closest_distance, closest_node = math.huge, nil
    for _, node in ipairs(nodes) do
        local start_row = node:range()
        if start_row > row and math.abs(start_row - row) < closest_distance then
            closest_node = node
            closest_distance = math.abs(start_row - row)
        end
    end
    return closest_node
end

---@param nodes TSNode[]
---@param row number
---@return TSNode
local function find_closest_previous_node_to_row(nodes, row)
    local closest_distance, closest_node = math.huge, nil
    for _, node in ipairs(nodes) do
        local _, _, end_row, _ = node:range()
        if end_row < row and math.abs(end_row - row) < closest_distance then
            closest_node = node
            closest_distance = math.abs(end_row - row)
        end
    end
    return closest_node
end

---@param o navigator_move_Args
---@return "start" | "end"
local function find_cursor_node_point_for_sibling(o)
    local destination_on_node = "start"
    if
        string.find(o.destination, "previous")
        and not lib_ts.node_start_and_end_on_same_line(catalyst.node())
    then
        destination_on_node = "end"
    end
    return destination_on_node
end

---@param o navigator_move_Args
---@return "start" | "end"
local function find_node_point_for_parent(o)
    local destination_on_node = "end"
    if
        string.find(o.destination, "previous")
        -- and not lib_ts.node_start_and_end_on_same_line(catalyst.node())
    then
        destination_on_node = "start"
    end
    return destination_on_node
end

---@param o navigator_move_Args
local function change_catalyst_node_to_its_sibling(o)
    local sibling_direction = string.find(o.destination, "next") and "next" or "previous"
    local next_siblings = aggregator.get_html_siblings(catalyst.node(), sibling_direction)

    if next_siblings[1] then
        catalyst.set_node(next_siblings[1])
        if string.find(o.destination, "sibling") then
            catalyst.set_node_point("start")
        else
            catalyst.set_node_point(find_cursor_node_point_for_sibling(o))
        end
        return next_siblings[1]
    end
end

---@param o navigator_move_Args
local function change_catalyst_node_to_its_parent(o)
    local parent_node = aggregator.get_html_node(catalyst.node():parent())
    if parent_node then
        catalyst.set_node(parent_node)
        catalyst.set_node_point(find_node_point_for_parent(o))
    end

    return parent_node
end

local function change_catalyst_node_to_next_closest_html_element()
    local html_nodes = aggregator.get_all_html_nodes_in_buffer(catalyst.buf())
    local _, _, end_row, _ = catalyst.node():range()
    local closest_next_node = find_closest_next_node_to_row(html_nodes, end_row)

    if closest_next_node then
        catalyst.set_node(closest_next_node)
        catalyst.set_node_point("start")
    end
end

local function change_catalyst_node_to_previous_closest_html_element()
    local html_nodes = aggregator.get_all_html_nodes_in_buffer(catalyst.buf())
    local start_row = catalyst.node():range()
    local closest_previous_node = find_closest_previous_node_to_row(html_nodes, start_row)

    if closest_previous_node then
        catalyst.set_node(closest_previous_node)
        catalyst.set_node_point("end")
    end
end

---@param html_children TSNode[]
local change_catalyst_to_its_first_child = function(html_children)
    catalyst.set_node(html_children[1])
    catalyst.set_node_point("start")
end

---@param html_children TSNode[]
local function change_catalyst_to_its_last_child(html_children)
    local last_child = html_children[#html_children]
    local node_point = "end"
    local start_row, _, end_row, _ = last_child:range()

    if start_row == end_row then node_point = "start" end

    local last_child_children = aggregator.get_html_children(last_child)
    if #last_child_children > 0 then node_point = "end" end

    catalyst.set_node(last_child)
    catalyst.set_node_point(node_point)
end

---@param o navigator_move_Args
M.move = function(o)
    if not catalyst.is_active() then return end

    local html_children = aggregator.get_html_children(catalyst.node())

    if o.destination == "next" then
        if
            #html_children > 0
            and lib_ts.cursor_is_at_start_of_node(catalyst.win(), catalyst.node())
        then
            change_catalyst_to_its_first_child(html_children)
        else
            if not change_catalyst_node_to_its_sibling(o) then
                if not change_catalyst_node_to_its_parent(o) then
                    change_catalyst_node_to_next_closest_html_element()
                end
            end
        end
    elseif o.destination == "previous" then
        if
            #html_children > 0 and lib_ts.cursor_is_at_end_of_node(catalyst.win(), catalyst.node())
        then
            change_catalyst_to_its_last_child(html_children)
        else
            if not change_catalyst_node_to_its_sibling(o) then
                if not change_catalyst_node_to_its_parent(o) then
                    change_catalyst_node_to_previous_closest_html_element()
                end
            end
        end
    end

    if o.destination == "next-sibling" or o.destination == "previous-sibling" then
        change_catalyst_node_to_its_sibling(o)
    elseif o.destination == "parent" then
        change_catalyst_node_to_its_parent(o)
        catalyst.set_node_point("start")
    end

    catalyst.move_to(o.select_move)
end

return M

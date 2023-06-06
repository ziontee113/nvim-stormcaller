local M = {}

---@class ExtmarkPosition
---@field row number
---@field col number

---@type ExtmarkPosition[][]
local undo_stack = {}

---@type ExtmarkPosition[][]
local redo_stack = {}

--------------------------------------------

local get_state = function(selection, ns)
    local state = {}
    if #selection > 0 then
        local buf = selection[1].buf
        for _, item in ipairs(selection) do
            local pos = vim.api.nvim_buf_get_extmark_by_id(buf, ns, item.extmark_id, {})
            table.insert(state, pos)
        end
    end
    return state
end

-------------------------------------------- Undo

---@param selection CatalystInfo[]
M.push_to_undo_stack = function(selection, ns)
    local state = get_state(selection, ns)
    table.insert(undo_stack, state)
end

M.pop_undo_stack = function()
    local latest = undo_stack[#undo_stack]
    table.remove(undo_stack, #undo_stack)
    return latest
end

-------------------------------------------- Redo

---@param selection CatalystInfo[]
M.push_to_redo_stack = function(selection, ns)
    local state = get_state(selection, ns)
    table.insert(redo_stack, state)
end

M.pop_redo_stack = function()
    local latest = redo_stack[#redo_stack]
    table.remove(redo_stack, #redo_stack)
    return latest
end

--------------------------------------------

return M

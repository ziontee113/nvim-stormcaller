local PopUp = require("deliberate.lib.ui.PopUp")
local Input = require("deliberate.lib.ui.Input")
local helpers = require("deliberate.helpers")
local utils = require("deliberate.lib.utils")

describe("PopUp", function()
    it("returns correct results - single PopUp", function()
        local myvar -- dummy variable to test callback result
        local popup = PopUp:new({
            steps = {
                {
                    items = {
                        { keymaps = { "l" }, text = "LE SSERAFIM" },
                        "",
                        { keymaps = { "u" }, text = "UNFORGIVEN" },
                    },
                    callback = function(results) myvar = results[1] end,
                },
            },
        })

        --------------------- check if PopUp has correct content

        popup:show()

        local popup_lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
        local want = {
            "l LE SSERAFIM",
            "",
            "u UNFORGIVEN",
        }
        assert.same(want, popup_lines)

        --------------------- check if myvar gets assigned new result value from callback

        utils.feed_keys("u")
        assert.equals("UNFORGIVEN", myvar)
        ---> popup should be altomatically hidden after accepting a choice. No need to manually call `popup:hide()`

        --------------------- 2nd time

        popup:show()
        utils.feed_keys("<CR>")
        assert.equals("LE SSERAFIM", myvar)
    end)

    it("aligns keymap hints to the right correctly", function()
        local popup = PopUp:new({
            steps = {
                {
                    items = {
                        { keymaps = { "le" }, text = "LE SSERAFIM" },
                        { keymaps = { "u" }, text = "UNFORGIVEN" },
                        { keymaps = { "f" }, text = "FEARLESS" },
                        { keymaps = { "bl" }, text = "BLUE FLAME" },
                    },
                    callback = function() end,
                },
            },
        })
        popup:show()
        local popup_lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
        local want = {
            "le LE SSERAFIM",
            " u UNFORGIVEN",
            " f FEARLESS",
            "bl BLUE FLAME",
        }
        assert.same(want, popup_lines)
    end)

    it("returns correct results - double PopUps", function()
        local final_result

        local popup = PopUp:new({
            steps = {
                {
                    items = {
                        { keymaps = { "1" }, text = "1st - " },
                        "",
                        { keymaps = { "2" }, text = "2nd - " },
                    },
                    format_fn = function(results, current_item)
                        return string.format("%s - %s", results[1], current_item.text)
                    end,
                },
                {
                    items = {
                        { keymaps = { "l" }, text = "LE SSERAFIM" },
                        "",
                        { keymaps = { "u" }, text = "UNFORGIVEN" },
                    },
                    callback = function(results) final_result = table.concat(results, "") end,
                },
            },
        })

        popup:show()
        utils.feed_keys("1")
        utils.feed_keys("l")

        assert.equals("1st - LE SSERAFIM", final_result)
    end)
end)

describe("PopUp items can be manipulated using callback function", function()
    it("works", function()
        local popup = PopUp:new({
            steps = {
                {
                    items = {
                        { keymaps = { "l" }, text = "LE SSERAFIM" },
                        { keymaps = { "u" }, text = "UNFORGIVEN" },
                        { keymaps = { "-" }, text = "", negatize = true, hidden = true },
                    },
                    callback = function(_, current_item, metadata)
                        if current_item.negatize == true then
                            local updated_items = {}
                            for _, item in ipairs(metadata.current_step_items) do
                                item.text = "-" .. item.text
                                table.insert(updated_items, item)
                            end

                            return {
                                increment_step_index_by = -1,
                                updated_items = updated_items,
                            }
                        end
                    end,
                },
            },
        })

        popup:show()

        utils.feed_keys("-")

        local popup_lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
        local want = {
            "l -LE SSERAFIM",
            "u -UNFORGIVEN",
        }
        assert.same(want, popup_lines)
    end)
end)

describe("PopUp combined with Input", function()
    it("returns correct callback result", function()
        local myvar

        local input = Input:new({
            callback = function(result) myvar = result end,
        })

        local popup = PopUp:new({
            steps = {
                {
                    items = {
                        { keymaps = { "l" }, text = "LE SSERAFIM" },
                        { keymaps = { "u" }, text = "UNFORGIVEN" },
                    },
                    callback = function(results)
                        input:show()
                        helpers.insert_chars_for_Input(input.buf, results[1])
                        utils.feed_keys("<CR>")
                    end,
                },
            },
        })

        popup:show()

        utils.feed_keys("u")
        assert.equals("UNFORGIVEN", myvar)
    end)
end)

local tcm = require("nvim-stormcaller.api.tailwind_class_modifier")
local catalyst = require("nvim-stormcaller.lib.catalyst")
local helpers = require("nvim-stormcaller.helpers")

describe("modify_padding()", function()
    after_each(function() vim.api.nvim_buf_delete(0, { force = true }) end)
    before_each(function() helpers.set_buffer_content_as_multiple_react_components() end)

    it("adds className property and specified class for tag with no classNames", function()
        vim.cmd("norm! 22gg^") -- cursor to <li>Contacts</li>

        catalyst.initiate({ win = 0, buf = 0 })
        helpers.assert_catalyst_node_has_text("<li>Contacts</li>")

        tcm.change_padding({ axis = "omni", modify_to = "p-4" })
        helpers.assert_catalyst_node_has_text('<li className="p-4">Contacts</li>')
    end)

    it("appends specified class for tag that already has classNames", function()
        vim.cmd("norm! 90gg^")

        catalyst.initiate({ win = 0, buf = 0 })
        helpers.assert_catalyst_node_has_text(
            '<h3 className="mt-4 text-sm text-gray-700">{image.name}</h3>'
        )

        tcm.change_padding({ axis = "omni", modify_to = "p-4" })
        helpers.assert_catalyst_node_has_text(
            '<h3 className="mt-4 text-sm text-gray-700 p-4">{image.name}</h3>'
        )
    end)

    -- it("replaces equivalent padding class axis", function()
    --     vim.cmd("norm! 22gg^") -- cursor to <li>Contacts</li>
    --     navigator.initiate({ win = 0, buf = 0 })
    --
    --     tcm.modify_padding({ axis = "omni", modify_to = "p-4" })
    --     helpers.assert_cursor_node_has_text('<li className="p-4">Contacts</li>')
    --
    --     tcm.modify_padding({ axis = "omni", modify_to = "p-8" })
    --     helpers.assert_cursor_node_has_text('<li className="p-8">Contacts</li>')
    -- end)
end)

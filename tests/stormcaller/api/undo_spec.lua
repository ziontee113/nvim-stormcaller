require("tests.editor_config")

local undo = require("stormcaller.api.undo")
local tag = require("stormcaller.api.html_tag")

local h = require("stormcaller.helpers")

describe("...", function()
    before_each(function() h.set_buffer_content_as_multiple_react_components() end)
    after_each(function() h.clean_up() end)

    it("...", function()
        h.initiate("22gg^", "<li>Contacts</li>")

        tag.add({ tag = "div", content = "", destination = "next" })
        h.selection_is(1, "<div></div>")

        undo.call()

        h.selection_is(1, "<li>Contacts</li>")
    end)
end)
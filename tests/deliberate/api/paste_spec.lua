require("tests.editor_config")

local selection = require("deliberate.lib.selection")
local yank = require("deliberate.api.yank")
local paste = require("deliberate.api.paste")
local h = require("deliberate.helpers")
local movA = h.move_then_assert_selection

describe("paste()", function()
    before_each(function() h.set_buffer_content_as_multiple_react_components() end)
    after_each(function() h.clean_up() end)

    it("destination = next, catalyst selection", function()
        h.initiate("22gg^", "<li>Contacts</li>")
        yank.call()
        paste.call({ destination = "next" })
        h.catalyst_has("<li>Contacts</li>", { 23, 8 })
        h.move("next", "<li>FAQ</li>", { 24, 8 })
    end)

    it(
        "destination = next, consecutive multi selection, paste targets same as selection",
        function()
            h.initiate("22gg^", "<li>Contacts</li>")
            movA({ "next", true }, 1, "<li>Contacts</li>")
            movA({ "next", true }, 2, { "<li>Contacts</li>", "<li>FAQ</li>" })
            yank.call()
            h.selection_is(1, "<OtherComponent />")

            movA("previous", 1, "<li>FAQ</li>")
            movA({ "previous", true }, 1, { "<li>FAQ</li>" })
            movA({ "previous", true }, 2, { "<li>FAQ</li>", "<li>Contacts</li>" })
            paste.call()
            h.node_has_text(
                selection.nodes()[1]:parent(),
                [[<div className="h-screen w-screen bg-zinc-900">
        <li>Home</li>
        <li>
          A new study found that coffee drinkers have a lower risk of liver
          cancer. So, drink up!
        </li>
        <li>Contacts</li>
        <li>Contacts</li>
        <li>FAQ</li>
        <li>FAQ</li>
        <li>Contacts</li>
        <li>FAQ</li>
        <OtherComponent />
      </div>]]
            )
            h.selection_is(2, { "<li>Contacts</li>", "<li>Contacts</li>" })
        end
    )

    it("destination = next, consecutive multi selection", function()
        h.initiate("22gg^", "<li>Contacts</li>")
        movA({ "next", true }, 1, "<li>Contacts</li>")
        movA({ "next", true }, 2, { "<li>Contacts</li>", "<li>FAQ</li>" })

        yank.call()
        h.selection_is(1, "<OtherComponent />") -- selection gets cleared if `yank.call()` with no args

        paste.call({ destination = "next" })
        h.catalyst_has("<li>Contacts</li>", { 25, 8 })
        h.node_has_text(
            selection.nodes()[1]:parent(),
            [[<div className="h-screen w-screen bg-zinc-900">
        <li>Home</li>
        <li>
          A new study found that coffee drinkers have a lower risk of liver
          cancer. So, drink up!
        </li>
        <li>Contacts</li>
        <li>FAQ</li>
        <OtherComponent />
        <li>Contacts</li>
        <li>FAQ</li>
      </div>]]
        )
    end)
end)

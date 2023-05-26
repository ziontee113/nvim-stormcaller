require("tests.editor_config")

local catalyst = require("stormcaller.lib.catalyst")
local helpers = require("stormcaller.helpers")

describe("catalyst.initiate() for tsx", function()
    before_each(function() vim.bo.ft = "typescriptreact" end)
    after_each(function() vim.api.nvim_buf_delete(0, { force = true }) end)

    it("puts cursor at start of closest tag, with initial cursor inside html_element", function()
        helpers.set_buf_content([[
export default function Home() {
  return (
    <>
      <div className="h-screen w-screen bg-zinc-900">
        <li>Home</li>
        <li>
          A new study found that coffee drinkers have a lower risk of liver
          cancer. So, drink up!
        </li>
        <li>Contacts</li>
        <li>FAQ</li>
      </div>
    </>
  )
}]])

        vim.cmd("norm! 7gg0ff") -- put cursor at line 7: A new study [f]ound that

        catalyst.initiate({ win = 0, buf = 0 }) -- should put cursor at line 6: [<]li>

        local cursor_positon = vim.api.nvim_win_get_cursor(0)
        assert.same({ 6, 8 }, cursor_positon)
    end)

    it(
        "puts cursor at start of closest tag, with initial cursor outside and above html_element",
        function()
            helpers.set_buf_content([[
export default function Home() {
  return (
    <>
      <div className="h-screen w-screen bg-zinc-900">
        <li>Home</li>
        <li>About</li>
        <li>Contacts</li>
        <li>FAQ</li>
      </div>
    </>
  )
}]])

            vim.cmd("norm! gg0") -- put cursor at line 1: {e}xport default ...

            catalyst.initiate({ win = 0, buf = 0 }) -- should put cursor at line 3: [<]>

            local cursor_positon = vim.api.nvim_win_get_cursor(0)
            assert.same({ 3, 4 }, cursor_positon)
        end
    )

    it(
        "puts cursor at end of closest tag, with initial cursor outside and below html_element",
        function()
            helpers.set_buf_content([[
export default function Home() {
  return (
    <>
      <div className="h-screen w-screen bg-zinc-900">
        <li>Home</li>
        <li>About</li>
        <li>Contacts</li>
        <li>FAQ</li>
      </div>
    </>
  )
}]])

            vim.cmd("norm! G0") -- put cursor at start of last line: [}]

            catalyst.initiate({ win = 0, buf = 0 }) -- should put cursor at line 10: </[>]

            local cursor_positon = vim.api.nvim_win_get_cursor(0)
            assert.same({ 10, 6 }, cursor_positon)
        end
    )

    it(
        [[puts cursor at end of closest html_element
because initial cursor was sandwiched between html_elements and was below closest html_element ]],
        function()
            helpers.set_buffer_content_as_multiple_react_components()
            vim.cmd("norm! 8gg0")

            catalyst.initiate({ win = 0, buf = 0 })

            local cursor_positon = vim.api.nvim_win_get_cursor(0)
            assert.same({ 6, 7 }, cursor_positon)
        end
    )

    it(
        [[puts cursor at start of closest html_element
because initial cursor was sandwiched between html_elements and was above closest html_element ]],
        function()
            helpers.set_buffer_content_as_multiple_react_components()
            vim.cmd("norm! 12gg0")

            catalyst.initiate({ win = 0, buf = 0 })

            local cursor_positon = vim.api.nvim_win_get_cursor(0)
            assert.same({ 15, 4 }, cursor_positon)
        end
    )
end)

describe("catalyst.initiate() for svelte()", function()
    before_each(function() helpers.set_buffer_content_as_svelte_file() end)
    after_each(function() helpers.clean_up() end)

    it("puts cursor at start of closest tag, initial cursor inside html_element", function()
        vim.cmd("norm! 32ggfm")
        catalyst.initiate({ win = 0, buf = 0 })

        helpers.assert_catalyst_node_has_text("<h1>Ligma</h1>")
        assert.same({ 32, 4 }, vim.api.nvim_win_get_cursor(0))
    end)

    it(
        "puts cursor at start of closest tag, initial cursor outside and above html_element",
        function()
            vim.cmd("norm! 30gg")
            catalyst.initiate({ win = 0, buf = 0 })

            helpers.assert_catalyst_node_has_text([[<section>
    <h1>Ligma</h1>
    <h3>is a made-up term</h3>
    <p>that gained popularity as part of an Internet prank or meme.</p>
</section>]])
            assert.same({ 31, 0 }, vim.api.nvim_win_get_cursor(0))
        end
    )

    it(
        "puts cursor at end of closest tag, with initial cursor outside and below html_element",
        function()
            vim.cmd("norm! 43gg")
            catalyst.initiate({ win = 0, buf = 0 })

            helpers.assert_catalyst_node_has_text([[<section>
    <h1>Ligma</h1>
    <h3>is a made-up term</h3>
    <p>that gained popularity as part of an Internet prank or meme.</p>
</section>]])
            assert.same({ 35, 9 }, vim.api.nvim_win_get_cursor(0))
        end
    )
end)

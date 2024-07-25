local ls = require("luasnip")

--[[
vim.keymap.set({"i", "s"}, "<C-E>", function()
	if ls.choice_active() then
		ls.change_choice(1)
	end
end, {silent = true})
--]]

return {
  "L3MON4D3/LuaSnip",
  keys = {
    {
      "<C-E>",
      function()
        if ls.choice_active() then
          ls.change_choice(1)
        end
      end,
      mode = { "i", "s" },
      { silent = true },
    },
  },
  config = function()
    local ls = require("luasnip")
    local rNeorg = require("r35.snippets.norg_snippets")
    local rInfisical = require("r35.snippets.infisical")
    ls.add_snippets("norg", {
      rNeorg.calendar_entry,
      rNeorg.free_time_entry,
      rNeorg.focus_time_entry,
      rNeorg.jira_ticket,
      rNeorg.ticket_notes,
    })
    ls.add_snippets("yaml", {
      rInfisical.infisical_secret,
    })
  end,
}

--[[
vim.keymap.set({"i", "s"}, "<C-E>", function()
	if ls.choice_active() then
		ls.change_choice(1)
	end
end, {silent = true})
--]]

return {
  "L3MON4D3/LuaSnip",
  enabled = true,
  build = "make install_jsregexp",
  dependencies = { "rafamadriz/friendly-snippets" },
  keys = {
    {
      "<C-E>",
      function()
        local ls = require("luasnip")
        if ls.choice_active() then
          ls.change_choice(1)
        end
      end,
      mode = { "i", "s" },
      { silent = true },
    },
  },
  config = function()
    require("luasnip.loaders.from_vscode").lazy_load()

    local ls = require("luasnip")
    local rNeorg = require("r35.snippets.norg_snippets")
    local rInfisical = require("r35.snippets.infisical")
    local rIstio = require("r35.snippets.k8s_istio")

    ls.config.set_config({
      store_selection_keys = "<Tab>",
    })

    -- Norg only snippets
    ls.add_snippets("norg", {
      rNeorg.calendar_entry,
      rNeorg.free_time_entry,
      rNeorg.focus_time_entry,
      rNeorg.jira_ticket,
      rNeorg.ticket_notes,
    })

    -- YAML only snippets
    ls.add_snippets("yaml", {
      rInfisical.infisical_secret,
      rIstio.virtual_service,
    })
  end,
}

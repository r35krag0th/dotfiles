-- This has been migrated to blink.cmp
return {
  "hrsh7th/nvim-cmp",
  enabled = false,
  -- dependencies = { "hrsh7th/cmp-emoji" },
  ---@param opts cmp.ConfigSchema
  opts = function(_, opts)
    table.insert(opts.sources, { name = "emoji" })
    table.insert(opts.sources, { name = "neorg" })
  end,
}

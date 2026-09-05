return {
  "vhyrro/luarocks.nvim",
  priority = 1000,
  config = true,
  opts = {
    -- This can get a little sussy when there are MITM surprises
    rocks = { "dkjson", "lua-curl", "nvim-nio", "mimetypes", "xml2lua" },
  },
}

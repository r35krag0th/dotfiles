return {
  "vhyrro/luarocks.nvim",
  priority = 1001,
  enabled = true,
  config = true,
  dir = "~/workspace/luarocks.nvim",
  opts = {
    -- This can get a little sussy when there are MITM surprises
    rocks = {
      "dkjson",
      "lua-curl",
      -- "nvim-nio",
      "mimetypes",
      "xml2lua",
    },
  },
}

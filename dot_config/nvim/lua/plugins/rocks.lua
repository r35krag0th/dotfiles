return {
  "vhyrro/luarocks.nvim",
  priority = 1000,
  config = true,
  opts = {
    rocks = { "lua-curl", "nvim-nio", "mimetypes", "xml2lua" },
    luarocks_build_args = {
      "--with-lua-include=/opt/homebrew/opt/luajit/include",
    },
  },
}

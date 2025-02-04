return {
  "Saghen/blink.cmp",
  opts = {
    completion = {
      enabled_providers = { "lsp", "path", "snippets", "buffer", "orgmode" },
    },
    providers = {
      orgmode = {
        name = "Orgmode",
        module = "orgmode.org.autocompletion.blink",
      },
    },
  },
}

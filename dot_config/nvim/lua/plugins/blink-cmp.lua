return {
  {
    "saghen/blink.compat",
    version = "2.*",
    enabled = true,
    lazy = true,
    opts = {
      impersonate_nvim_cmp = true,
      debug = true,
    },
  },
  {
    "Saghen/blink.cmp",
    version = "1.*",
    enabled = true,
    dependencies = {
      { "hrsh7th/cmp-emoji" },
      { "rafamadriz/friendly-snippets" },
      { "giuxtaposition/blink-cmp-copilot" },
    },
    opts_extend = { "sources.default" },
    opts = {
      completion = {
        menu = {
          draw = {
            columns = {
              { "kind_icon" },
              { "label", "label_description", gap = 1 },
              { "source_name", "source_deco", "kind", gap = 1 },
              { "score" },
            },
            components = {
              source_deco = {
                ellipsis = false,
                text = function(ctx)
                  return " "
                end,
              },
              score = {
                ellipsis = false,
                text = function(ctx)
                  return " 󰒠 " .. ctx.item.score_offset
                end,
                highlight = "BlinkCmpSignatureHelpActiveParameter",
              },
              -- kind_icon = {
              --   text = function(ctx)
              --     local kind_icon, _, _ = require("mini.icons").get("lsp", ctx.kind)
              --     return kind_icon
              --   end,
              --   highlight = function(ctx)
              --     local _, hl, _ = require("mini.icons").get("lsp", ctx.kind)
              --     return hl
              --   end,
              -- },
              -- kind = {
              --   highlight = function(ctx)
              --     local _, hl, _ = require("mini.icons").get("lsp", ctx.kind)
              --     return hl
              --   end,
              -- },
            },
            treesitter = {
              "lsp",
            },
          },
        },
        ghost_text = {
          enabled = true,
        },
      },
      -- Using: https://cmp.saghen.dev/configuration/keymap.html#enter
      keymap = {
        ["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
        ["<C-e>"] = { "hide", "fallback" },
        ["<CR>"] = { "accept", "fallback" },

        ["<Tab>"] = { "snippet_forward", "fallback" },
        ["<S-Tab>"] = { "snippet_backward", "fallback" },

        ["<Up>"] = { "select_prev", "fallback" },
        ["<Down>"] = { "select_next", "fallback" },
        ["<C-p>"] = { "select_prev", "fallback_to_mappings" },
        ["<C-n>"] = { "select_next", "fallback_to_mappings" },

        ["<C-b>"] = { "scroll_documentation_up", "fallback" },
        ["<C-f>"] = { "scroll_documentation_down", "fallback" },

        ["<C-k>"] = { "show_signature", "hide_signature", "fallback" },
      },
      sources = {
        default = { "lsp", "path", "snippets", "buffer", "emoji" },
        providers = {
          emoji = {
            name = "emoji",
            module = "blink.compat.source",
            score_offset = -3,
            opts = {},
          },
          buffer = {
            enabled = true,
          },
        },
      },
    },
  },
}

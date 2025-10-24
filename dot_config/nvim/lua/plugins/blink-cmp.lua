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
    "saghen/blink.cmp",
    version = "1.*",
    enabled = true,
    dependencies = {
      { "hrsh7th/cmp-emoji" },
      { "rafamadriz/friendly-snippets" },
      { "giuxtaposition/blink-cmp-copilot" },
      { "onsails/lspkind.nvim" },
    },
    opts_extend = { "sources.default" },
    opts = {
      fuzzy = { implementation = "prefer_rust_with_warning" },
      cmdline = {
        keymap = { preset = "inherit" },
        completion = {
          menu = {
            auto_show = true,
          },
        },
      },
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
              kind_icon = {
                text = function(ctx)
                  local icon = ctx.kind_icon
                  if vim.tbl_contains({ "Path" }, ctx.source_name) then
                    local dev_icon, _ = require("nvim-web-devicons").get_icon(ctx.label)
                    if dev_icon then
                      icon = dev_icon
                    end
                  else
                    icon = require("lspkind").symbolic(ctx.kind, {
                      mode = "symbol",
                    })
                  end

                  return icon .. ctx.icon_gap
                end,

                -- Optionally, use the highlight groups from nvim-web-devicons
                -- You can also add the same function for `kind.highlight` if you want to
                -- keep the highlight groups in sync with the icons.
                highlight = function(ctx)
                  local hl = ctx.kind_hl
                  if vim.tbl_contains({ "Path" }, ctx.source_name) then
                    local dev_icon, dev_hl = require("nvim-web-devicons").get_icon(ctx.label)
                    if dev_icon then
                      hl = dev_hl
                    end
                  end
                  return hl
                end,
              },
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

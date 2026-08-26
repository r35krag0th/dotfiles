local norg_icons = require("r35.utils.norg_icons")
local M = {}

function M.plugins()
  -- Useful Utils:
  -- "lith" -- a static site generator from norg files
  --    cargo install --git https://github.com/norgolith/core norgolith
  --    cargo install --git https://github.com/norgolith/core norgolith-mcp
  return {
    {
      -- Wrap lines based on their concealed width instead of their unconcealed width.
      -- https://github.com/benlubas/neorg-conceal-wrap
      "benlubas/neorg-conceal-wrap",
    },
    {
      -- Neorg Dew: Breadcrumb in win-bar
      -- https://github.com/setupyourskills/dew-crumb
      "setupyourskills/dew-crumb",
      ft = "norg",
      dependencies = {
        "setupyourskills/neorg-dew",
      },
    },
    {
      -- Neorg Dew: Include an block of text from the linked to file
      -- https://github.com/setupyourskills/dew-transclude
      "setupyourskills/dew-transclude",
      ft = "norg",
      dependencies = {
        "setupyourskills/neorg-dew",
        "setupyourskills/dew-highlights", -- Optional for colorization
      },
    },
    {
      -- Effectively the norg search engine
      -- https://github.com/benlubas/neorg-se
      --
      -- :Neorg search index
      -- :Neorg search query fulltext
      -- :Neorg search query categories
      "benlubas/neorg-se",
    },
    {
      -- The "interim" LSP for norg
      -- https://github.com/benlubas/neorg-interim-ls
      "benlubas/neorg-interim-ls",
    },
    {
      -- Neorg Dew: Category Picker (uses Teleport)
      -- https://github.com/setupyourskills/dew-catngo
      "setupyourskills/dew-catngo",
      dependencies = {
        "setupyourskills/neorg-dew",
        "benlubas/neorg-query",
        "nvim-telescope/telescope.nvim",
      },
    },
    {
      "nvim-neorg/neorg",
      dependencies = {
        "luarocks.nvim",
        "nvim-neorg/tree-sitter-norg",
        "nvim-neorg/tree-sitter-norg-meta",
        "folke/zen-mode.nvim",
        "max397574/neorg-contexts",
        {
          "pysan3/neorg-templates",
          dependencies = {
            "L3MON4D3/LuaSnip",
          },
        },
        "opipoy/neorg-colors",
        "setupyourskills/dew-crumb",
      },
      lazy = false,
      version = "*",
      config = true,
      keys = {
        -- Journal Days
        { "<localleader>jo", "<cmd>Neorg journal today<CR>", desc = "Open Today's Journal" },
        { "<localleader>jy", "<cmd>Neorg journal yesterday<CR>", desc = "Open Yesterday's Journal" },
        { "<localleader>jt", "<cmd>Neorg journal tomorrow<CR>", desc = "Open Tomorrow's Journal" },
        -- Journal ToC (index)
        { "<localleader>ju", "<cmd>Neorg journal toc update<CR>", desc = "Update the Journal TOC index" },
        { "<localleader>jT", "<cmd>Neorg journal toc open<CR>", desc = "Open the Journal TOC index" },
        -- Journal Template Loader
        { "<localleader>jl", "<cmd>Neorg templates load journalv2<CR>", desc = "Apply Journal v2 Template" },
        -- Neorg globals -> index management
        { "<localleader>Ni", "<cmd>Neorg index<CR>", desc = "Open Workspace Index" },
        {
          "<localleader>Ngws",
          function()
            require("r35.utils.norg").regenerate_summary()
          end,
          desc = "Regenerate Workspace Summary Under Heading",
        },
        -- Neorg globals -> search
        { "<localleader>Nsc", "<cmd>Neorg search query categories<CR>", desc = "Search Categories" },
        { "<localleader>Nsf", "<cmd>Neorg search query fulltext<CR>", desc = "Full-Text Search this Workspace" },
      },
      opts = {
        load = {
          ["core.defaults"] = {},
          ["core.tempus"] = {},
          ["core.completion"] = {
            config = {
              -- NOTE: you can hook nvim-cmp directly
              -- engine = "nvim-cmp",

              -- NOTE: you can also use the interim-ls
              engine = {
                module_name = "external.lsp-completion",
              },
            },
          },
          ["core.integrations.nvim-cmp"] = {},
          ["core.concealer"] = {
            config = {
              -- Icons are written as \u{} escapes on purpose. These glyphs live in
              -- the Private Use Area and render as nothing in most editors, diffs
              -- and terminals, so pasting them as literals is a silent-corruption
              -- trap -- one went missing that way already.
              --
              -- They render two cells wide; see lua/r35/glyphs.lua and
              -- ~/.config/kitty/conf.d/nerd_font_widths.conf for why.
              icons = {
                -- Rendered across the whole `(x)`, brackets and all: at two cells
                -- these no longer fit inside the parentheses, and neorg's stock
                -- renderer would overlay one cell too far and eat the `)`. See
                -- r35.utils.norg_icons.
                todo = norg_icons.todo({
                  undone = "\u{F0C8}", -- fa-square-o
                  pending = "\u{F252}", -- fa-hourglass-half
                  done = "\u{F00C}", -- fa-check
                  on_hold = "\u{F04C}", -- fa-pause
                  cancelled = "\u{F05E}", -- fa-ban
                  urgent = "\u{F071}", -- fa-exclamation-triangle
                  uncertain = "\u{F128}", -- fa-question
                  recurring = "\u{F021}", -- fa-refresh
                }),
                definition = {
                  single = { icon = "\u{F02D}" }, -- fa-book
                  multi_prefix = { icon = "\u{F02D} " },
                  multi_suffix = { icon = "\u{F02D} " },
                },
                footnote = {
                  single = { icon = "\u{F249}" }, -- fa-sticky-note
                  multi_prefix = { icon = "\u{F249} " },
                  multi_suffix = { icon = "\u{F249} " },
                },
                markup = {
                  spoiler = { icon = "\u{F070}" }, -- fa-eye-slash
                },
                -- Deliberately left at neorg's defaults:
                --   quote     "|" is box drawing and already correct
                --   ordered   "1." / "A." / "i." are text labels, not icons
                --   heading   the geometric ramp stays single width; Nerd Font
                --             equivalents would take two cells and push every
                --             heading right
              },
            },
          },
          ["core.dirman"] = {
            config = {
              workspaces = {
                -- The Core notes
                notes = "~/notes",
                -- TTRPG Session Notes
                session_notes = "~/session-notes",
                -- Keeping this here for now
                old_notes = "~/Documents/Neorg-Notes/",
              },
              default_workspace = "notes",
            },
          },
          ["core.journal"] = {
            config = {
              strategy = "nested",
            },
          },
          ["core.looking-glass"] = {},
          ["core.qol.toc"] = {},
          ["core.qol.todo_items"] = {},
          ["core.summary"] = {
            config = {
              strategy = "default",
            },
          },
          ["core.promo"] = {},
          ["core.export"] = { config = { extensions = "all" } },
          ["core.export.markdown"] = {},
          ["core.presenter"] = {
            config = {
              zen_mode = "zen-mode",
            },
          },
          ["core.ui"] = {},
          ["core.ui.calendar"] = {},
          ["core.tangle"] = {
            config = {
              tangle_on_write = true,
              indent_errors = true,
              report_on_empty = true,
            },
          },
          ["external.context"] = {},
          ["external.templates"] = {
            config = {
              keywords = {
                ["YESTERDAY_N_FILENAME"] = function()
                  local r = require("r35.utils.norg")
                  local ls = require("luasnip")
                  return ls.text_node(r.journal_path_for(-1))
                end,
                ["TODAY_N_FILENAME"] = function()
                  local r = require("r35.utils.norg")
                  local ls = require("luasnip")
                  return ls.text_node(r.journal_path_for(0))
                end,
                ["TOMORROW_N_FILENAME"] = function()
                  local r = require("r35.utils.norg")
                  local ls = require("luasnip")
                  return ls.text_node(r.journal_path_for(1))
                end,
                ["WEEK_NUMBER"] = function()
                  local ls = require("luasnip")
                  local s = require("neorg.modules.external.templates.default_snippets")
                  return ls.text_node(os.date("%V", s.file_tree_date()))
                end,
                ["WEEKDAY_SHORT"] = function()
                  local ls = require("luasnip")
                  local s = require("neorg.modules.external.templates.default_snippets")
                  return ls.text_node(os.date("%a", s.file_tree_date()))
                end,
                ["DAY"] = function()
                  local ls = require("luasnip")
                  local s = require("neorg.modules.external.templates.default_snippets")
                  return ls.text_node(os.date("%d", s.file_tree_date()))
                end,
                ["MONTH"] = function()
                  local ls = require("luasnip")
                  local s = require("neorg.modules.external.templates.default_snippets")
                  return ls.text_node(os.date("%m", s.file_tree_date()))
                end,
                ["MONTH_SHORT"] = function()
                  local ls = require("luasnip")
                  local s = require("neorg.modules.external.templates.default_snippets")
                  return ls.text_node(os.date("%h", s.file_tree_date()))
                end,
                ["YEAR"] = function()
                  local ls = require("luasnip")
                  local s = require("neorg.modules.external.templates.default_snippets")
                  return ls.text_node(os.date("%Y", s.file_tree_date()))
                end,
                ["DAY_ORDINAL"] = function()
                  local ls = require("luasnip")
                  local s = require("neorg.modules.external.templates.default_snippets")
                  local r = require("r35.utils.norg")
                  local dt = os.date("*t", s.file_tree_date())
                  return ls.text_node(r.day_ordinal(dt.day))
                end,
                ["QUARTER"] = function()
                  local ls = require("luasnip")
                  local r = require("r35.utils.norg")
                  return ls.text_node(string.format("%d", r.current_quarter()))
                end,
                ["PREVIOUS_QUARTER"] = function()
                  local ls = require("luasnip")
                  local r = require("r35.utils.norg")
                  return ls.text_node(string.format("%d", r.previous_quarter()))
                end,
                ["NEXT_QUARTER"] = function()
                  local ls = require("luasnip")
                  local r = require("r35.utils.norg")
                  return ls.text_node(string.format("%d", r.next_quarter()))
                end,
              },
              -- snippets_overwrite = {
              --   date_format = [[%Y/%m/%d]],
              -- },
            },
          },
          ["core.integrations.treesitter"] = {
            config = {
              configure_parsers = true,
            },
          },
          ["external.neorg-dew"] = {},
          ["external.dew-crumb"] = {
            config = {
              enabled = true, -- Enable or disable the module on startup
              separator = ">", -- The character to use as a separator
            },
          },
          -- ["external.neorg-query"] = {},
          ["external.dew-catngo"] = {
            config = {
              exclude_cat_prefix = "#", -- all categories prefixed by "#" will be ignored
            },
          },
          ["external.dew-transclude"] = {
            config = {
              block_end_marker = "===", -- Marks the end of the level 1 heading block for content extraction
              no_title = true, -- Set to `true` to disable the title extraction
              colorify = false, -- Set to `true` to colorize the extracted content see `colors`
            },
          },
          ["external.search"] = {
            -- values shown are the default
            config = {
              -- Index the workspace when neovim launches. This process happens on a separate thread, so
              -- it doesn't significantly contribute to startup time or block neovim
              index_on_start = true,
            },
          },
          ["external.interim-ls"] = {
            config = {
              completion_provider = {
                enable = true,
                documentation = true,
                -- Try to complete norg categories (provided by norg-query)
                categories = true,
                -- Suggesting heading completions from the given file for `{@x|}` where `|` is your cursor,
                -- and `x` is an alphanumeric character.
                --
                -- `{@name}` expands to `[name]{:$/people:# name}`
                people = {
                  enable = true,
                  -- Path to the name file relative to the workspace root without the .norg extension.
                  path = "people",
                },
              },
            },
          },
          ["external.conceal-wrap"] = {},
          ["core.esupports.metagen"] = {
            config = {
              type = "auto",
            },
          },
        },
      },
    },
  }
end

function M.init() end

return M

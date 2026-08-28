local norg_icons = require("r35.utils.norg_icons")
local icons = require("r35.glyphs.icons")

---An ISO-8601 timestamp carrying the offset that is actually in effect.
---
---Replaces neorg's own `get_timestamp`, which is wrong for half the year. Its
---`get_timezone_offset()` measures the offset at `os.date("*t", 0)` -- epoch 0,
---i.e. 1970-01-01 -- and additionally forces `isdst = false`. Both lines are
---lifted from a lua-users wiki snippet answering "what is this zone's STANDARD
---offset?", which is a correct answer to a different question. For
---America/Chicago the result is a fixed -0600: right in winter, an hour wrong
---all summer, and silently so.
---
---`os.date("%z")` asks the C library for the offset in effect NOW, DST included.
---That is POSIX strftime, so it holds on macOS and Linux. If it ever returns
---something that is not [+-]HHMM the offset is omitted rather than guessed --
---an absent offset is recoverable, a confidently wrong one is not.
---
---Wired in via `core.esupports.metagen`'s `template`, which is a supported
---config surface: entries naming only a field fall back to neorg's default, so
---this replaces `created`/`updated` and nothing else.
---@return string
local function timestamp()
  local stamp = os.date("%Y-%m-%dT%H:%M:%S")
  local offset = os.date("%z")
  if type(offset) == "string" and offset:match("^[+-]%d%d%d%d$") then
    return stamp .. offset
  end
  return stamp
end

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
        -- "phenax/neorg-hop-extras", -- Allows adding custom functionality to links!
        {
          "https://gitlab.r35.dev/r35krag0th/neorg-hopscotch.nvim",
          name = "neorg-hopscotch",
          dev = true,
          dir = "~/workspace/neorg-hopscotch.nvim/",
        },
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
      opts = function(_, opts)
        local di = require("nvim-web-devicons.icons-default")
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
                -- Icons are named rather than written as codepoints. The escapes
                -- were there because PUA glyphs render as nothing in diffs and on
                -- the web -- a silent-corruption trap that ate one already. A name
                -- cannot be corrupted that way, and a typo is now an ERROR
                -- diagnostic on the line rather than a silently missing icon.
                --
                -- `undone` was U+F0C8, which is a FILLED square in Nerd Fonts v3.
                -- `fa_square_o` is the outline the old `-- fa-square-o` comment
                -- always meant; a filled box for "undone" reads as done.
                --
                -- They render two cells wide; see lua/r35/glyphs/blocks.lua and
                -- ~/.config/kitty/conf.d/nerd_font_widths.conf for why.
                icons = {
                  -- Rendered across the whole `(x)`, brackets and all: at two cells
                  -- these no longer fit inside the parentheses, and neorg's stock
                  -- renderer would overlay one cell too far and eat the `)`. See
                  -- r35.utils.norg_icons.
                  todo = norg_icons.todo({
                    undone = icons.fa_square_o,
                    pending = icons.fa_hourglass_half,
                    done = icons.fa_check,
                    on_hold = icons.fa_pause,
                    cancelled = icons.fa_ban,
                    urgent = icons.fa_exclamation_triangle,
                    uncertain = icons.fa_question,
                    recurring = icons.fa_refresh,
                  }),
                  definition = {
                    single = { icon = icons.fa_book },
                    multi_prefix = { icon = icons.fa_book .. " " },
                    multi_suffix = { icon = icons.fa_book .. " " },
                  },
                  footnote = {
                    single = { icon = icons.fa_sticky_note },
                    multi_prefix = { icon = icons.fa_sticky_note .. " " },
                    multi_suffix = { icon = icons.fa_sticky_note .. " " },
                  },
                  markup = {
                    spoiler = { icon = icons.fa_eye_slash },
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
                -- Entries naming only a field keep neorg's default behaviour;
                -- created/updated are overridden because neorg's own timestamp
                -- reports a fixed -0600 here. See `timestamp` at the top.
                template = {
                  { "title" },
                  { "description" },
                  { "authors" },
                  { "categories" },
                  { "created", timestamp },
                  { "updated", timestamp },
                  { "version" },
                },
              },
            },
            ["external.hopscotch"] = {
              config = {
                -- Resolves the built-in aliases' symbolic icon names (fa_github_alt,
                -- fa_npm, dev_rust, ...) to glyphs. Must be the SILENT lookup: the
                -- indexing form reports unknown names against the calling file, which
                -- for hopscotch's own defaults would be its source, not this config.
                icon_provider = icons.get,
                aliases = {
                  -- GitHub.com
                  ghi = {
                    url = "https://github.com/{}",
                    url_formatter = function(args)
                      return string.format("%s/issues/%s", args[1], args[2])
                    end,
                    icon = icons.cod_github_alt,
                    display_formatter = function(args)
                      return string.format("%s %s", args[1], args[2])
                    end,
                  },
                  ghpr = {
                    url = "https://github.com/{}",
                    url_formatter = function(args)
                      return string.format("%s/pull/%s", args[1], args[2])
                    end,
                    icon = icons.cod_github_alt,
                    display_formatter = function(args)
                      return string.format("%s %s%s", args[1], icons.cod_git_merge, args[2])
                    end,
                  },
                  -- gitlab.r35.dev
                  gl = {
                    url = "https://gitlab.r35.dev/{}",
                    url_formatter = function(args)
                      return args[1]
                    end,
                    icon = "",
                  },
                  glmr = {
                    url = "https://gitlab.r35.dev/{}",
                    icon = "",
                    url_formatter = function(args)
                      return args[1] .. "/-/merge_requests/" .. args[2]
                    end,
                    display_formatter = function(args)
                      return vim.fn.fnamemodify(args[1], ":t") .. "!" .. args[2]
                    end,
                  },
                  glwi = {
                    url = "https://gitlab.r35.dev/{}",
                    icon = "",
                    url_formatter = function(args)
                      return args[1] .. "/-/work_items/" .. args[2]
                    end,
                    display_formatter = function(args)
                      return vim.fn.fnamemodify(args[1], ":t") .. "#" .. args[2]
                    end,
                  },
                },
              },
            },
          },
        }

        return opts
      end,
    },
  }
end

function M.init() end

return M

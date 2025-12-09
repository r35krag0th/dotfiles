local M = {}

-- We need parsers:
--
-- :TSInstall markdown markdown_inline html latex typst yaml
function M.plugins()
  return {
    { "iamcco/markdown-preview.nvim", enabled = false },
    "jghauser/follow-md-links.nvim",
    {
      "OXY2DEV/markview.nvim",
      lazy = false,
      version = "26.*",
      dependencies = {
        -- enable blink.cmp support
        "saghen/blink.cmp",
        -- "nvim-tree/nvim-web-devicons",
        "nvim-mini/mini.icons",
      },
      opts = function(_, opts)
        require("markview.extras.checkboxes").setup({
          --- Default checkbox state(used when adding checkboxes).
          ---@type string
          default = " ",

          --- Changes how checkboxes are removed.
          ---@type
          ---| "disable" Disables the checkbox.
          ---| "checkbox" Removes the checkbox.
          ---| "list_item" Removes the list item markers too.
          remove_style = "list_item",

          --- Various checkbox states.
          ---
          --- States are in sets to quickly change between them
          --- when there are a lot of states.
          ---@type string[][]
          states = {
            { " ", "/", "X" },
            { "<", ">" },
            { "?", "!", "*" },
            { '"' },
            { "l", "b", "i" },
            { "S", "I" },
            { "p", "c" },
            { "f", "k", "w" },
            { "u", "d" },
          },
        })

        require("markview.extras.headings").setup()
        require("markview.extras.editor").setup()
        local presets = require("markview.presets")

        opts = opts or {}
        opts = vim.tbl_deep_extend("force", opts, {
          checkboxes = {
            enable = true,

            checked = { text = "", hl = "MarkviewCheckboxChecked" },
            unchecked = { text = "󰄱", hl = "@text.todo" },
            pending = { text = "󰰱", hl = "@text.todo" },
            custom = {
              { match = ">", text = "", hl = "@text.todo" },
              { match = "!", text = "", hl = "@text.todo" },
            },
          },

          ---
          markdown = {
            headings = presets.headings.glow,
            table = presets.headings.rounded,
            tables = {
              enable = true,
              use_virt_lines = true, -- so don't need to add spaces for table-outline to match inner text

              text = {
                {
                  --    Main parts    Seperators
                  "╭",
                  "─",
                  "╮",
                  "┬",
                  "├",
                  "│",
                  "┤",
                  "┼",
                  "╰",
                  "─",
                  "╯",
                  "┴",

                  --    Alignment indicators
                  --   Left   right     center
                  "╼",
                  "╾",
                  "╴",
                  "╶",
                },
              },
            },
            checkboxes = presets.checkboxes.nerd,
            list_items = {
              enable = true,
              shift_width = 2,

              marker_minus = { "•" },
              marker_plus = { "•" },
              marker_star = { "•" },
              marker_dot = { "•" },
            },
          },
          preview = {
            -- icon_provider = "devicons",
            -- icon_provider = "mini",
            icon_provider = "internal",
            linewise_hybrid_mode = true,
            hybrid_modes = { "i" },
            -- use "Hybrid-Mode" for live-rendering
            modes = { "n", "i", "v", "V", "no", "c" },
          },
          markdown_inline = {
            enabled = true,
            checkboxes = {
              enable = true,
            },
            email = {
              enable = true,
            },
          },
          -- You can set custom icons for URLs here
          hyperlinks = {
            enable = true,
          },
        })
        return opts
      end,
      keys = {
        { "<localleader>td", "<cmd>Checkbox toggle<cr>", desc = "Markview: Toggle checkbox" },
        { "<localleader>th", "<cmd>Checkbox change -1 0<cr>", desc = "Markview: Prev column of symbols" },
        { "<localleader>tj", "<cmd>Checkbox change 0 -1<cr>", desc = "Markview: Next row of symbols" },
        { "<localleader>tk", "<cmd>Checkbox change 0 1<cr>", desc = "Markview: Prev row of symbols" },
        { "<localleader>tl", "<cmd>Checkbox change 1 0<cr>", desc = "Markview: Next column of symbols" },
      },
    },
    {
      "r35krag0th/yeahnotes.nvim",
      lazy = false,
      dev = true,
      dir = "~/workspace/yeahnotes.nvim",
      dependencies = {
        "nvim-mini/mini.pick", -- Required for find/grep functionality
      },
      opts = {
        root = vim.fn.expand("~/notes"), -- Default notes directory
      },
      keys = {
        { "<localleader>nd", desc = "YeahNotes: Today" },
        { "<localleader>ny", desc = "YeahNotes: Yesterday" },
        { "<localleader>nt", desc = "YeahNotes: Tomorrow" },
        { "<localleader>np", desc = "YeahNotes: Previous day" },
        { "<localleader>nP", desc = "YeahNotes: Previous (skip empty)" },
        { "<localleader>nn", desc = "YeahNotes: Next day" },
        { "<localleader>nN", desc = "YeahNotes: Next (skip empty)" },
        { "<localleader>nf", desc = "YeahNotes: Find files" },
        { "<localleader>ng", desc = "YeahNotes: Grep notes" },
        { "<localleader>nm", desc = "YeahNotes: Migrate tasks to tomorrow" },
        { "<localleader>nM", desc = "YeahNotes: Migrate and open tomorrow" },
      },
    },
  }
end

function M.init()
  --
end

return M

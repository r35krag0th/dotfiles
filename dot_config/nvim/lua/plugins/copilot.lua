return {
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    dependencies = {
      { "github/copilot.vim" }, -- or zbirenbaum/copilot.lua
      { "nvim-lua/plenary.nvim", branch = "master" }, -- for curl, log and async functions
    },
    build = "make tiktoken", -- Only on MacOS or Linux
    opts = {
      agents = {
        {
          name = "Explain Code",
          instructions = "Explain what the selected code does in simple terms.",
        },
        {
          name = "Find Bugs",
          instructions = "Review the code for bugs or logical errors.",
        },
        {
          name = "Optimize Code",
          instructions = "Suggest improvements for performance and readability.",
        },
      },
    },
    -- See Commands section for default commands if you want to lazy load on them
  },
}

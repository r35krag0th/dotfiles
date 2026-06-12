-- We don't use Perl anymore :)
vim.g.loaded_perl_provider = 0

-- NOTE: For the providers
-- pip install -U pynvim
-- mise use npm:neovim --global
-- mise use gem:neovim --global
--
-- NOTE: PYTHON PROVIDER SETUP
-- We use a uv virtualenv to hold pynvim
-- uv venv --seed --no-project --python (mise which -t python@3.14 python3) ~/.local/venv/neovim-0.12
--
-- NOTE: `pynvim` is then installed/managed via:
-- ~/.local/venv/neovim-0.12/bin/pip install -U pynvim
vim.g.python3_host_prog = os.getenv("HOME") .. "/.local/venv/neovim-0.12/bin/python3"

-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

-- Configure the core LSP stuff
require("r35.lsp").setup()

-- Finally, set the theme
require("r35.themes").setTheme()

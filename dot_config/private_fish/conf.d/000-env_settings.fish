set -l script_name (status -f)

# General Path Settings to call once
set -Ux R35_HOMEBREW_DIR (brew --prefix)
set -Ux R35_HOMEBREW_BIN $R35_HOMEBREW_DIR/bin
set -Ux EDITOR $R35_HOMEBREW_BIN/nvim

set -Ux GOPATH "$HOME/go"

set -Ux SHELL fish

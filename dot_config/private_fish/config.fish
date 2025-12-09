# NOTE: "mise" has replaced goenv, pyenv, nvm, and pyenv.

if status is-interactive
    # Commands to run in interactive sessions can go here
end

# You will want Fisher installed:
#  https://github.com/jorgebucaran/fisher?tab=readme-ov-file#installation
#
# fisher install jorgebucaran/autopair.fish
# fisher install decors/fish-colored-man

# Add some additional paths
fish_add_path -g --prepend "$HOME/.krew/bin"
fish_add_path -g --prepend "$HOME/.local/bin"
fish_add_path -g "$GOPATH/bin"
fish_add_path -g "$HOME/.cargo/bin"
fish_add_path -g --prepend "$HOME/.local/share/bob/nvim-bin"

# Initialize Zoxide -- https://github.com/ajeetdsouza/zoxide
zoxide init fish | source

# Setup "mise" -- https://mise.jdx.dev
~/.local/bin/mise activate fish | source

# NOTE: We can only determine this AFTER "mise" is activated
# BUG: Except this fails probably from a race condition or something?
# calling the shim directly works.
set -gx R35_GO_BIN_DIR (~/.local/share/mise/shims/go version 2>/dev/null | cut -d' ' -f3 | tr -d 'go')

# TODO: This really needs to be part of a hook
if test -n "$R35_GO_BIN_DIR"
    fish_add_path -g "$GOPATH/$R35_GO_BIN_DIR/bin"
end

# NOTE: This is required by docker helpers
fish_add_path -g --prepend /usr/local/bin

# Initialize the Starship prompt -- https://starship.rs/
starship init fish | source

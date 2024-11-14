# NOTE: "mise" has replaced goenv, pyenv, nvm, and pyenv.

if status is-interactive
    # Commands to run in interactive sessions can go here
end

# Completion Support from Homebrew
# NOTE: The `R35_HOMEBREW_DIR` variable is set in the `000-env_settings.fish` file.
if test -d $R35_HOMEBREW_DIR/share/fish/completions
    set -p fish_complete_path $R35_HOMEBREW_DIR/share/fish/completions
end

if test -d $R35_HOMEBREW_DIR/share/fish/vendor_completions.d
    set -p fish_complete_path $R35_HOMEBREW_DIR/share/fish/vendor_completions.d
end

# You will want Fisherman installed:
#  https://github.com/jorgebucaran/fisher?tab=readme-ov-file#installation
#
# fisher install jorgebucaran/autopair.fish
# fisher install decors/fish-colored-man


# Add some additional paths
fish_add_path -u --prepend "$HOME/.local/bin"
fish_add_path -u "$R35_HOMEBREW_BIN"
fish_add_path -u "$GOPATH/bin"

# Load the "abbr" items
abbr -a -- ggl 'git checkout main && git fetch -pPt && git pull -p'
abbr -a -- g git
abbr -a -- k kubectl
abbr -a -- ls 'eza --icons'
abbr -a -- ll 'eza --icons --git --header --long'
abbr -a -- la 'eza --icons --git --header --long --all'
abbr -a -- n $R35_HOMEBREW_BIN/nvim
abbr -a -- v $R35_HOMEBREW_BIN/nvim
abbr -a -- edit $R35_HOMEBREW_BIN/nvim
abbr -a -- tffu 'terraform force-unlock'
abbr -a -- tgfu 'terragrunt force-unlock'
abbr -a -- gsm 'git switch main && git fetch -pP && git pull'
abbr -a -- t $R35_HOMEBREW_BIN/tmux
abbr -a -- tf terraform
abbr -a -- tg terragrunt
abbr -a -- tmux "$R35_HOMEBREW_BIN/tmux -u -2"
abbr -a -- ta 'tmux attach -dt'
abbr -a -- vim $R35_HOMEBREW_BIN/nvim
abbr -a -- chez chezmoi
abbr -a -- c chezmoi

# Initialize Zoxide -- https://github.com/ajeetdsouza/zoxide
zoxide init fish | source

# Setup "mise" -- https://mise.jdx.dev
~/.local/bin/mise activate fish | source

# NOTE: We can only determine this AFTER "mise" is activated
# BUG: Except this fails probably from a race condition or something?
# calling the shim directly works.
set -gx R35_GO_BIN_DIR (~/.local/share/mise/shims/go version | cut -d' ' -f3 | tr -d 'go')

# TODO: This really needs to be part of a hook
fish_add_path -u "$GOPATH/$R35_GO_BIN_DIR/bin"

# Initialize the Starship prompt -- https://starship.rs/
starship init fish | source

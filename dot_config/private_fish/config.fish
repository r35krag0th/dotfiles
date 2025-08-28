# NOTE: "mise" has replaced goenv, pyenv, nvm, and pyenv.

if status is-interactive
    # Commands to run in interactive sessions can go here
end

# You will want Fisherman installed:
#  https://github.com/jorgebucaran/fisher?tab=readme-ov-file#installation
#
# fisher install jorgebucaran/autopair.fish
# fisher install decors/fish-colored-man

# Add some additional paths
fish_add_path -u --prepend "$HOME/.krew/bin"
fish_add_path -u --prepend "$HOME/.local/bin"
fish_add_path -u "$GOPATH/bin"
fish_add_path -u "$HOME/.cargo/bin"

# Load the "abbr" items
# fetch with prune, prune tags, and update tags
# pull with prune and update tags
abbr -a -- g-sm 'git switch main && git fetch -pP && git pull'
abbr -a -- g-gl "git fetch -pPt && git pull -pt"
abbr -a -- g-fgl "git fetch -pPt --force && git pull -pt"
# Branch switching
abbr -a -- gstm "git switch main"
# Commit shortcuts
abbr -a -- k kubectl
abbr -a -- ls 'eza --icons --'
abbr -a -- ll 'eza --icons --git --header --long --'
abbr -a -- la 'eza --icons --git --header --long --all --'
# This needs to be updated to better handle installs from bob and mise
abbr -a -- tffu 'terraform force-unlock'
abbr -a -- tgfu 'terragrunt force-unlock'
abbr -a -- tf terraform
abbr -a -- tg terragrunt
abbr -a -- ta 'tmux attach -dt'
abbr -a -- chez chezmoi
abbr -a -- c chezmoi
abbr -a -- gp 'git push --tags --prune --'
abbr -a dl -- 'curl -fsSL'
abbr -a grab -- 'curl -fsSL'

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

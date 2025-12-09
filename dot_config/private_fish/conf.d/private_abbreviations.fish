# Fish abbreviations - consolidated from various config files
# Abbreviations expand inline when you press space, unlike aliases

# Editor shortcuts (uses $R35_HOMEBREW_BIN if set, otherwise defaults)
if set -q R35_HOMEBREW_BIN
    abbr -a -- n "$R35_HOMEBREW_BIN/nvim"
    abbr -a -- v "$R35_HOMEBREW_BIN/nvim"
    abbr -a -- vim "$R35_HOMEBREW_BIN/nvim"
    abbr -a -- t "$R35_HOMEBREW_BIN/tmux"
    abbr -a -- tmux "$R35_HOMEBREW_BIN/tmux -u -2"
else
    abbr -a -- n nvim
    abbr -a -- v nvim
    abbr -a -- vim nvim
    abbr -a -- t tmux
end

# Modern CLI replacements
abbr -a -- find fd
abbr -a -- grep rg
abbr -a -- help tldr
abbr -a -- http 'http --style=material'

# eza (modern ls replacement)
abbr -a -- ls 'eza --icons --'
abbr -a -- ll 'eza --icons --git --header --long --'
abbr -a -- la 'eza --icons --git --header --long --all --'
abbr -a -- lt 'eza --tree --level=2 --icons'

# Kubernetes
abbr -a -- k kubectl

# Terraform/Terragrunt
abbr -a -- tf terraform
abbr -a -- tg terragrunt
abbr -a -- tffu 'terraform force-unlock'
abbr -a -- tgfu 'terragrunt force-unlock'

# Tmux
abbr -a -- ta 'tmux attach -dt'

# Chezmoi
abbr -a -- chez chezmoi
abbr -a -- c chezmoi

# Downloads
abbr -a -- dl 'curl -fsSL'
abbr -a -- grab 'curl -fsSL'

# Git workflow shortcuts (complement the g* functions)
# NOTE: gp is a function, not an abbreviation - use it directly
abbr -a -- g-sm 'git switch main && git fetch -pP && git pull'
abbr -a -- gstm 'git switch main'

# Git Fetch Flags:
# -p => Prune: removes remote-tracking refs that no longer exist on remote
# -P => Prune Tags: removes local tags that no longer exist on remote
# -t => Update Tags: fetch all tags from remote
abbr -a -- g-gl 'git fetch -pPt && git pull -pt'
abbr -a -- g-fgl 'git fetch -pPt --force && git pull -pt'

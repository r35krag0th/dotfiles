set -Ux R35_HOMEBREW_DIR ""
if test -d /opt/homebrew -o -x /opt/homebrew/bin/brew
    set -Ux R35_HOMEBREW_DIR /opt/homebrew
else if test -d /usr/local/Homebrew -o -x /usr/local/bin/brew
    set -Ux R35_HOMEBREW_DIR /usr/local/Homebrew
else if test -d /home/linuxbrew/.linuxbrew -o -x /home/linuxbrew/.linuxbrew/bin/brew
    set -Ux R35_HOMEBREW_DIR /home/linuxbrew/.linuxbrew
else if test -d $HOME/.linuxbrew -o -x $HOME/.linuxbrew/bin/brew
    set -Ux R35_HOMEBREW_DIR $HOME/.linuxbrew
else
    echo "Homebrew not found. Please install Homebrew first." >&2
    exit 1
end

# Detect the presence
if test -n "$R35_HOMBREW_DIR"
    set -Ux R35_HOMEBREW_BIN $R35_HOMEBREW_DIR/bin
    set -Ux EDITOR $R35_HOMEBREW_BIN/nvim
    fish_add_path -u "$R35_HOMEBREW_BIN"

    abbr -a -- n $R35_HOMEBREW_BIN/nvim
    abbr -a -- v $R35_HOMEBREW_BIN/nvim
    abbr -a -- edit $R35_HOMEBREW_BIN/nvim
    abbr -a -- t $R35_HOMEBREW_BIN/tmux
    abbr -a -- tmux "$R35_HOMEBREW_BIN/tmux -u -2"
    abbr -a -- vim $R35_HOMEBREW_BIN/nvim

    alias assume="source $R35_HOMEBREW_BIN/assume.fish"

    # Completion Support from Homebrew
    # NOTE: The `R35_HOMEBREW_DIR` variable is set in the `000-env_settings.fish` file.
    if test -d $R35_HOMEBREW_DIR/share/fish/completions
        set -p fish_complete_path $R35_HOMEBREW_DIR/share/fish/completions
    end

    if test -d $R35_HOMEBREW_DIR/share/fish/vendor_completions.d
        set -p fish_complete_path $R35_HOMEBREW_DIR/share/fish/vendor_completions.d
    end
else
    # NOT using homebrew
end
# General Path Settings to call once

set -Ux GOPATH "$HOME/go"
set -Ux SHELL fish

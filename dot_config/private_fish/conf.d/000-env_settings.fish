# Homebrew detection - only set if not already configured
if not set -q R35_HOMEBREW_DIR; or test -z "$R35_HOMEBREW_DIR"
    if test -d /opt/homebrew -o -x /opt/homebrew/bin/brew
        set -gx R35_HOMEBREW_DIR /opt/homebrew
    else if test -d /usr/local/Homebrew -o -x /usr/local/bin/brew
        set -gx R35_HOMEBREW_DIR /usr/local/Homebrew
    else if test -d /home/linuxbrew/.linuxbrew -o -x /home/linuxbrew/.linuxbrew/bin/brew
        set -gx R35_HOMEBREW_DIR /home/linuxbrew/.linuxbrew
    else if test -d $HOME/.linuxbrew -o -x $HOME/.linuxbrew/bin/brew
        set -gx R35_HOMEBREW_DIR $HOME/.linuxbrew
    else
        # Homebrew not found - just skip setup, don't kill the shell
        set -gx R35_HOMEBREW_DIR ""
    end
end

# Configure Homebrew paths and settings if available
if test -n "$R35_HOMEBREW_DIR"
    set -gx R35_HOMEBREW_BIN $R35_HOMEBREW_DIR/bin
    set -gx EDITOR $R35_HOMEBREW_BIN/nvim
    fish_add_path -g "$R35_HOMEBREW_BIN"

    # Completion Support from Homebrew
    if test -d $R35_HOMEBREW_DIR/share/fish/completions
        set -p fish_complete_path $R35_HOMEBREW_DIR/share/fish/completions
    end

    if test -d $R35_HOMEBREW_DIR/share/fish/vendor_completions.d
        set -p fish_complete_path $R35_HOMEBREW_DIR/share/fish/vendor_completions.d
    end
end

# General environment settings
set -gx GOPATH "$HOME/go"
set -gx SHELL (command -s fish)

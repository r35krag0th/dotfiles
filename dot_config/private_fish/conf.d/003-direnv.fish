# direnv hook for fish
# Only setup if direnv is available

# Check common locations for direnv
set -l direnv_bin ""
if command -q direnv
    set direnv_bin (command -s direnv)
else if test -x /opt/homebrew/bin/direnv
    set direnv_bin /opt/homebrew/bin/direnv
else if test -x /usr/local/bin/direnv
    set direnv_bin /usr/local/bin/direnv
else if test -x $HOME/.local/bin/direnv
    set direnv_bin $HOME/.local/bin/direnv
end

if test -n "$direnv_bin"
    eval ($direnv_bin hook fish)
end

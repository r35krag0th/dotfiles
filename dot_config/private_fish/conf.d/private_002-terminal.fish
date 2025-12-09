# Terminal compatibility - handle xterm-kitty for SSH and other contexts
# Many remote systems don't have xterm-kitty terminfo installed

# Function to check if terminfo exists for a given TERM
function __fish_terminfo_exists
    # Try to use infocmp to check if terminfo exists
    command infocmp $argv[1] >/dev/null 2>&1
end

# If we're in an SSH session and TERM is xterm-kitty, check compatibility
if set -q SSH_TTY; or set -q SSH_CONNECTION
    # We're in an SSH session
    if test "$TERM" = "xterm-kitty"
        # Check if the remote system has xterm-kitty terminfo
        if not __fish_terminfo_exists xterm-kitty
            # Fall back to xterm-256color which is universally available
            set -gx TERM xterm-256color
        end
    end
end

# Ensure COLORTERM is set for true color support when using kitty
if test "$TERM" = "xterm-kitty"; and not set -q COLORTERM
    set -gx COLORTERM truecolor
end

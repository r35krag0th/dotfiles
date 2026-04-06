# AWS assume role helper (granted.dev)
# Sources the assume.fish script from Homebrew
function assume -d "Assume an AWS role using granted"
    set -l mise_granted_root (mise where granted)
    if test -d $mise_granted_root; and test -f $mise_granted_root/assume.fish
        source "$mise_granted_root/assume.fish" $argv
    else if set -q R35_HOMEBREW_BIN; and test -f "$R35_HOMEBREW_BIN/assume.fish"
        source "$R35_HOMEBREW_BIN/assume.fish" $argv
    else if test -f /opt/homebrew/bin/assume.fish
        source "/opt/homebrew/bin/assume.fish" $argv
    else
        echo "assume.fish not found - install granted: brew install common-fate/granted/granted" >&2
        return 1
    end
end

if command -v radiant 2>/dev/null
    # Abbreviations, because I'm lazy
    abbr -a -- rad radiant
    abbr -a -- r radiant

    # Load completion
    radiant completion fish | source
end

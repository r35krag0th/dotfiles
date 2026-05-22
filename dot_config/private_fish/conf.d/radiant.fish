if command -v radiant >/dev/null
    # Abbreviations, because I'm lazy
    abbr -a -- rad radiant
    abbr -a -- r radiant

    # Load completion (is this triggering 1password?)
    radiant completion fish | source
end

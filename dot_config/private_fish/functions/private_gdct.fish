function gdct -d "Show the most recent tag"
    git describe --tags (git rev-list --tags --max-count=1) $argv
end

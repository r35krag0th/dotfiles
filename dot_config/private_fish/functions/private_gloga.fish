function gloga -d "Show all commit history as a graph"
    git log --oneline --decorate --graph --all $argv
end

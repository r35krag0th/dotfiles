function glgga -d "Show all branches commit history as a graph"
    git log --graph --decorate --all $argv
end

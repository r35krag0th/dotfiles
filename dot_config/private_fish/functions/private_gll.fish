function gll -d "Show abbreviated commit history as a graph"
    git log --graph --pretty=oneline --abbrev-commit $argv
end

function glgm -d "Show last 10 commits as a graph"
    git log --graph --max-count=10 $argv
end

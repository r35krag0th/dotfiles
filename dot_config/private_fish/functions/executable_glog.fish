function glog -d "Show commit history as a graph"
    git log --oneline --decorate --graph $argv
end

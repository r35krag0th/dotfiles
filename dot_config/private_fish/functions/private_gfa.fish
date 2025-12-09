function gfa -d "Fetch all remotes and prune deleted branches"
    git fetch --all --prune --jobs=10 $argv
end

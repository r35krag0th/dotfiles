function gcas -d "Commit all changes with signoff"
    git commit --all --signoff $argv
end

function gcpa -d "Abort current cherry-pick operation"
    git cherry-pick --abort $argv
end

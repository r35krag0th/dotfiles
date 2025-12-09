function groh -d "Hard reset current branch to origin"
    git reset origin/(git_current_branch) --hard $argv
end

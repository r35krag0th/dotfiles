function ggsup -d "Set upstream for current branch to origin"
    git branch --set-upstream-to=origin/(git_current_branch)
end

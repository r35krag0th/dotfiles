function ggp -d "Push current branch to origin"
    git push origin (git_current_branch) $argv
end

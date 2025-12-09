function ggl -d "Pull current branch from origin"
    git pull origin (git_current_branch) $argv
end

function ggpur -d "Pull current branch from origin with rebase"
    git pull --rebase origin (git_current_branch) $argv
end

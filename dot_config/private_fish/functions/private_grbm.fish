function grbm -d "Rebase current branch onto main branch"
    git rebase (git_main_branch) $argv
end

function grbd -d "Rebase current branch onto development branch"
    git rebase (git_develop_branch) $argv
end

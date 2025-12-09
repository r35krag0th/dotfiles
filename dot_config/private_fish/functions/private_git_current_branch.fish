function git_current_branch -d "Get the current git branch name"
    if git rev-parse --git-dir >/dev/null 2>&1
        git branch --show-current 2>/dev/null
    end
end

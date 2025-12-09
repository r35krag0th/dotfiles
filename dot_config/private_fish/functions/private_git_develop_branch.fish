function git_develop_branch -d "Detect and return the development branch (dev, develop, etc.)"
    if not git rev-parse --git-dir >/dev/null 2>&1
        return 1
    end

    for branch in dev devel develop development
        if git show-ref -q --verify refs/heads/$branch
            echo $branch
            return 0
        end
    end

    echo develop
    return 1
end

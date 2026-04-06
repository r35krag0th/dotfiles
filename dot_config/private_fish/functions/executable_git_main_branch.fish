function git_main_branch -d "Detect and return the main branch (main, master, etc.)"
    if not git rev-parse --git-dir >/dev/null 2>&1
        return 1
    end

    for ref in refs/heads/main refs/heads/trunk refs/heads/mainline refs/heads/default refs/heads/stable refs/heads/master
        if git show-ref -q --verify $ref
            echo (basename $ref)
            return 0
        end
    end

    echo master
    return 1
end

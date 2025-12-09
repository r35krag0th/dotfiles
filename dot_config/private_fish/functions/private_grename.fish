function grename -d "Rename a branch locally and on remote"
    if test (count $argv) -ne 2
        echo "Usage: grename <old_branch> <new_branch>"
        return 1
    end

    set old_branch $argv[1]
    set new_branch $argv[2]

    git branch -m $old_branch $new_branch
    if git config --get branch.$old_branch.remote >/dev/null
        git push origin :$old_branch
        git push --set-upstream origin $new_branch
    end
end

function gstu -d "Stash including untracked files"
    git stash push --include-untracked $argv
end

function gstall -d "Stash all files including ignored ones"
    git stash push --all $argv
end

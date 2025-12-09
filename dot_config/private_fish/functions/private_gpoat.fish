function gpoat -d "Push all branches and tags to origin"
    git push origin --all && git push origin --tags $argv
end

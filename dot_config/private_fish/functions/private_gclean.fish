function gclean -d "Clean untracked files interactively"
    git clean --interactive -d $argv
end

function gunignore -d "Unmark files as assumed unchanged"
    git update-index --no-assume-unchanged $argv
end

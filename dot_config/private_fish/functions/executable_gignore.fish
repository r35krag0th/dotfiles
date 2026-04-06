function gignore -d "Mark files as assumed unchanged"
    git update-index --assume-unchanged $argv
end

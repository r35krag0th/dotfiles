function gbnm -d "List branches not merged into current branch"
    git branch --no-merged $argv
end

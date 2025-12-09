function gbda -d "Delete all merged branches except main/master/develop"
    git branch --no-color --merged | command grep -vE "^(\+|\*|\s*(master|main|develop|dev)\s*\$)" | command xargs -n 1 git branch -d
end

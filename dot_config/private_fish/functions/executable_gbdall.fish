function gbdall -d "Force delete all branches except main/master/develop"
    git branch --no-color | command grep -vE "^(\+|\*|\s*(master|main|develop|dev)\s*\$)" | command xargs -n 1 git branch -D
end

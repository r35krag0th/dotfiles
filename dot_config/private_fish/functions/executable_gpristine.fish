function gpristine -d "Reset to HEAD and clean all untracked files"
    git reset --hard && git clean --force -d $argv
end

function 'gcans!' -d "Amend commit with signoff, no edit"
    git commit --verbose --all --signoff --no-edit --amend $argv
end

function 'gcan!' -d "Amend commit without editing message"
    git commit --verbose --all --no-edit --amend $argv
end

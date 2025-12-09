function gupav -d "Pull with rebase, autostash, and verbose output"
    git pull --rebase --autostash --verbose $argv
end

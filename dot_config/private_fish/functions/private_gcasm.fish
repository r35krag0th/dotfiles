function gcasm -d "Commit all changes with signoff and message"
    git commit --all --signoff --message $argv
end

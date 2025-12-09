function glgp -d "Show commit history with patches"
    git log --stat --patch $argv
end

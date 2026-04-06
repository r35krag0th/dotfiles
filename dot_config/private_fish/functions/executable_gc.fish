# Git commit functions
# Note: gc! variants are also defined here (macOS case-insensitive filesystem)

function gc -d "Create a commit with verbose output"
    git commit --verbose $argv
end

function 'gc!' -d "Amend the last commit"
    git commit --verbose --amend $argv
end

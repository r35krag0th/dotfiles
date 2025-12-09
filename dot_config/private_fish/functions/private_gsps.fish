function gsps -d "Show commit with signature verification"
    git show --pretty=short --show-signature $argv
end

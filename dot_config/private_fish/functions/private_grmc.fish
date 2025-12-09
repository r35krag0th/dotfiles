function grmc -d "Remove files from git but keep on filesystem"
    git rm --cached $argv
end

function gdt -d "Show files changed in a commit"
    git diff-tree --no-commit-id --name-only -r $argv
end

# Note: gbD (force delete) is also available - use: git branch -D <branch>
function gbd -d "Delete a branch"
    git branch --delete $argv
end

# Force delete variant (since macOS is case-insensitive)
function gbD -d "Force delete a branch"
    git branch --delete --force $argv
end

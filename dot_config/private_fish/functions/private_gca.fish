# Git commit all functions
function gca -d "Commit all tracked changes"
    git commit --verbose --all $argv
end

function 'gca!' -d "Amend commit with all tracked changes"
    git commit --verbose --all --amend $argv
end

# Git push functions
function gp -d "Push changes to remote"
    git push $argv
end

function 'gpf!' -d "Force push (dangerous, overwrites remote)"
    git push --force $argv
end

function gbso -d "Mark current commit as old in bisect"
    git bisect old $argv
end

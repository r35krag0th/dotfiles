function gbsb -d "Mark current commit as bad in bisect"
    git bisect bad $argv
end

function gbsg -d "Mark current commit as good in bisect"
    git bisect good $argv
end

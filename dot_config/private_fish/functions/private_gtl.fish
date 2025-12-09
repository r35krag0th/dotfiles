function gtl -d "List tags matching a pattern"
    git tag --sort=-v:refname -n --list "$argv[1]*"
end

function gtv -d "List tags sorted by version"
    git tag | sort -V $argv
end

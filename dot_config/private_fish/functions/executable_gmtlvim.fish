function gmtlvim -d "Run vimdiff merge tool to resolve conflicts"
    git mergetool --no-prompt --tool=vimdiff $argv
end

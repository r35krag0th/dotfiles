function gdcw -d "Show staged changes word by word"
    git diff --cached --word-diff $argv
end

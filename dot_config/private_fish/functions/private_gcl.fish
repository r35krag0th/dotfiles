function gcl -d "Clone a repository with submodules"
    git clone --recurse-submodules $argv
end

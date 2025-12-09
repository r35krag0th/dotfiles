function grt -d "Go to git repository root directory"
    cd (git rev-parse --show-toplevel; or echo .) $argv
end

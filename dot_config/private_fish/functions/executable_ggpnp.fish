function ggpnp -d "Pull from and push to origin for current branch"
    if test (count $argv) -eq 0
        ggl && ggp
    else
        ggl $argv && ggp $argv
    end
end

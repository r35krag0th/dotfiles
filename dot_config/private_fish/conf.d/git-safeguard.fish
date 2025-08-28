function git
    if test "$argv[1]" = "push"
        for arg in $argv[2..]
            if string match -q "*--prune*" -- $arg
                for other_arg in $argv[2..]
                    if string match -q "*--tags*" -- $other_arg
                        echo "⚠️  WARNING: --prune with --tags will delete remote tags!"
                        echo "Use 'git push --tags' instead to safely push tags"
                        return 1
                    end
                end
            end
        end
    end
    command git $argv
end
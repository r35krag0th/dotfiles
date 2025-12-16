function img-copy --description "Copy image between registries"
    if test (count $argv) -ne 2
        echo "Usage: img-copy <src> <dst>"
        return 1
    end

    skopeo copy docker://$argv[1] docker://$argv[2]
end

function img-inspect --description "Inspect image metadata"
    if test (count $argv) -lt 1
        echo "Usage: img-inspect <image[:tag]>"
        return 1
    end

    skopeo inspect docker://$argv[1] | jq
end

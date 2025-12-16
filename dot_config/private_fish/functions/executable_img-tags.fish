function img-tags --description "List tags for a container image"
    if test (count $argv) -lt 1
        echo "Usage: img-tags <image>"
        return 1
    end

    skopeo list-tags docker://$argv[1] \
        | jq -r '.Tags[]' \
        | sort -V
end

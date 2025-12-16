function img-labels --description "Show image labels"
    skopeo inspect docker://$argv[1] \
        | jq '.Labels'
end

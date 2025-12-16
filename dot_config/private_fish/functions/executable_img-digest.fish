function img-digest --description "Get image digest"
    skopeo inspect docker://$argv[1] \
        | jq -r '.Digest'
end
